// Supabase Edge Function: 네이버 OAuth 콜백 처리
// 네이버 OAuth 인증 후 추가 처리가 필요한 경우 사용합니다.
// 주의: Supabase가 기본적으로 OAuth를 처리하므로, 이 함수는 선택사항입니다.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface NaverAuthCallbackRequest {
  code?: string
  state?: string
  error?: string
  error_description?: string
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
    // URL 쿼리 파라미터 또는 요청 본문에서 정보 추출
    const url = new URL(req.url)
    const code = url.searchParams.get('code') || (await req.json()).code
    const state = url.searchParams.get('state') || (await req.json()).state
    const error = url.searchParams.get('error') || (await req.json()).error

    // 에러 처리
    if (error) {
      console.error('네이버 OAuth 오류:', error)
      return new Response(
        JSON.stringify({ 
          error: '네이버 OAuth 인증 실패', 
          details: error 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 주의: 실제 OAuth 인증은 Supabase가 처리합니다.
    // 이 함수는 추가적인 후처리(예: 사용자 프로필 동기화)를 위한 것입니다.
    
    // code가 있으면 Supabase에서 사용자 정보를 가져올 수 있습니다.
    // 하지만 일반적으로는 Supabase의 기본 OAuth 처리를 사용하는 것이 좋습니다.

    return new Response(
      JSON.stringify({
        success: true,
        message: '네이버 OAuth 콜백 처리 완료',
        note: 'Supabase가 기본적으로 OAuth를 처리합니다. 추가 처리가 필요한 경우 sync-naver-profile 함수를 사용하세요.',
        code: code ? '인증 코드 수신됨' : '인증 코드 없음',
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  } catch (error) {
    console.error('네이버 OAuth 콜백 처리 실패:', error)
    return new Response(
      JSON.stringify({ 
        error: '네이버 OAuth 콜백 처리 실패', 
        details: error instanceof Error ? error.message : String(error) 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

