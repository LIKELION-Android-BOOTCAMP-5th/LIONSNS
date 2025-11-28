// Supabase Edge Function: 네이버 사용자 프로필 동기화
// 네이버 OAuth 로그인 후 사용자 프로필 정보를 동기화합니다.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface SyncNaverProfileRequest {
  userId: string
  accessToken?: string  // 네이버 액세스 토큰 (선택사항, Supabase에서 가져올 수 있으면 생략 가능)
}

interface NaverUserInfo {
  resultcode: string
  message: string
  response: {
    id: string
    nickname?: string
    name?: string
    email?: string
    profile_image?: string
    age?: string
    gender?: string
    birthday?: string
    birthyear?: string
    mobile?: string
  }
}

serve(async (req) => {
  // CORS 헤더 설정
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  // OPTIONS 요청 처리 (CORS preflight)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 요청 본문 파싱
    const { userId, accessToken }: SyncNaverProfileRequest = await req.json()

    if (!userId) {
      return new Response(
        JSON.stringify({ error: 'userId는 필수입니다' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Supabase 클라이언트 생성 (서비스 역할 키 사용)
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // 사용자 정보 조회
    const { data: user, error: userError } = await supabase.auth.admin.getUserById(userId)

    if (userError || !user) {
      console.error('사용자 조회 실패:', userError)
      return new Response(
        JSON.stringify({ error: '사용자를 찾을 수 없습니다', details: userError?.message }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 네이버 provider로 로그인한 사용자인지 확인
    const provider = user.user.app_metadata?.provider
    if (provider !== 'naver') {
      return new Response(
        JSON.stringify({ error: '네이버 로그인 사용자가 아닙니다', provider }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 네이버 사용자 정보 조회
    // 주의: Supabase가 OAuth를 처리하므로, userMetadata에 이미 정보가 있을 수 있습니다.
    // 하지만 네이버 API에서 최신 정보를 가져와서 동기화할 수 있습니다.
    
    let naverUserInfo: NaverUserInfo | null = null

    // accessToken이 제공된 경우 네이버 API에서 직접 조회
    if (accessToken) {
      try {
        const naverResponse = await fetch('https://openapi.naver.com/v1/nid/me', {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
          },
        })

        if (naverResponse.ok) {
          naverUserInfo = await naverResponse.json()
          
          if (naverUserInfo.resultcode !== '00') {
            console.error('네이버 API 오류:', naverUserInfo.message)
            naverUserInfo = null
          }
        } else {
          console.error('네이버 API 요청 실패:', naverResponse.status)
        }
      } catch (error) {
        console.error('네이버 API 호출 실패:', error)
        // 네이버 API 호출 실패해도 userMetadata에서 정보 사용
      }
    }

    // 사용자 프로필 정보 추출
    const userMetadata = user.user.user_metadata || {}
    const naverResponse = naverUserInfo?.response

    // 프로필 정보 구성 (네이버 API 응답 우선, 없으면 userMetadata 사용)
    const profileData = {
      name: naverResponse?.name || 
            naverResponse?.nickname || 
            userMetadata.full_name || 
            userMetadata.name || 
            user.user.email?.split('@')[0] || 
            '사용자',
      email: naverResponse?.email || 
             user.user.email || 
             '',
      profile_image_url: naverResponse?.profile_image || 
                         userMetadata.avatar_url || 
                         null,
      provider: 'naver',
    }

    // user_profiles 테이블에 프로필 정보 저장/업데이트
    const { data: profile, error: profileError } = await supabase
      .from('user_profiles')
      .upsert({
        id: userId,
        name: profileData.name,
        email: profileData.email,
        profile_image_url: profileData.profile_image_url,
        provider: profileData.provider,
        updated_at: new Date().toISOString(),
      }, {
        onConflict: 'id',
      })
      .select()
      .single()

    if (profileError) {
      console.error('프로필 저장 실패:', profileError)
      return new Response(
        JSON.stringify({ 
          error: '프로필 저장 실패', 
          details: profileError.message 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Supabase Auth의 user_metadata도 업데이트 (선택사항)
    if (naverUserInfo?.response) {
      try {
        await supabase.auth.admin.updateUserById(userId, {
          user_metadata: {
            full_name: profileData.name,
            name: profileData.name,
            avatar_url: profileData.profile_image_url,
            email: profileData.email,
            naver_id: naverUserInfo.response.id,
            ...(naverUserInfo.response.nickname && { nickname: naverUserInfo.response.nickname }),
          },
        })
      } catch (error) {
        console.error('user_metadata 업데이트 실패 (무시 가능):', error)
        // user_metadata 업데이트 실패해도 프로필은 저장됨
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: '네이버 프로필 동기화 완료',
        profile: {
          id: profile.id,
          name: profile.name,
          email: profile.email,
          profile_image_url: profile.profile_image_url,
          provider: profile.provider,
        },
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  } catch (error) {
    console.error('네이버 프로필 동기화 실패:', error)
    return new Response(
      JSON.stringify({ 
        error: '네이버 프로필 동기화 실패', 
        details: error instanceof Error ? error.message : String(error) 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

