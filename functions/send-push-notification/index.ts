// Supabase Edge Function: 푸시 알림 전송
// Firebase Cloud Messaging을 사용하여 푸시 알림을 전송합니다.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface PushNotificationRequest {
  userId: string
  title: string
  body: string
  data?: {
    type?: string
    postId?: string
    commentId?: string
    [key: string]: any
  }
}

interface DeviceToken {
  device_token: string
  device_type: 'ios' | 'android' | 'web'
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
    // FCM 서버 키 확인
    if (!FCM_SERVER_KEY) {
      console.error('FCM_SERVER_KEY가 설정되지 않았습니다')
      return new Response(
        JSON.stringify({ error: 'FCM_SERVER_KEY가 설정되지 않았습니다' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 요청 본문 파싱
    const { userId, title, body, data }: PushNotificationRequest = await req.json()

    if (!userId || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'userId, title, body는 필수입니다' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Supabase 클라이언트 생성 (서비스 역할 키 사용)
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // 사용자의 FCM 토큰 조회
    const { data: tokens, error: tokenError } = await supabase
      .from('device_tokens')
      .select('device_token, device_type')
      .eq('user_id', userId)

    if (tokenError) {
      console.error('토큰 조회 실패:', tokenError)
      return new Response(
        JSON.stringify({ error: '토큰 조회 실패', details: tokenError.message }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    if (!tokens || tokens.length === 0) {
      console.log(`사용자 ${userId}의 FCM 토큰을 찾을 수 없습니다`)
      return new Response(
        JSON.stringify({ error: 'FCM 토큰을 찾을 수 없습니다' }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 각 토큰에 대해 푸시 알림 전송
    const results = await Promise.allSettled(
      tokens.map(async (token: DeviceToken) => {
        // FCM 메시지 페이로드 구성
        const fcmPayload: any = {
          to: token.device_token,
          notification: {
            title: title,
            body: body,
          },
        }

        // 데이터 페이로드 추가 (선택사항)
        if (data) {
          fcmPayload.data = {
            ...data,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          }
        }

        // iOS의 경우 추가 설정
        if (token.device_type === 'ios') {
          fcmPayload.notification.sound = 'default'
          fcmPayload.notification.badge = '1'
        }

        // FCM에 푸시 알림 요청
        const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            'Authorization': `key=${FCM_SERVER_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(fcmPayload),
        })

        if (!fcmResponse.ok) {
          const errorText = await fcmResponse.text()
          throw new Error(`FCM 요청 실패: ${fcmResponse.status} - ${errorText}`)
        }

        const result = await fcmResponse.json()
        return { token: token.device_token, result }
      })
    )

    // 결과 처리
    const successes = results.filter(r => r.status === 'fulfilled')
    const failures = results.filter(r => r.status === 'rejected')

    console.log(`${successes.length}개 알림 전송 성공, ${failures.length}개 실패`)

    return new Response(
      JSON.stringify({
        success: true,
        sent: successes.length,
        failed: failures.length,
        results: results.map(r => 
          r.status === 'fulfilled' 
            ? { success: true, ...r.value }
            : { success: false, error: r.reason?.message || '알 수 없는 오류' }
        ),
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  } catch (error) {
    console.error('푸시 알림 전송 실패:', error)
    return new Response(
      JSON.stringify({ 
        error: '푸시 알림 전송 실패', 
        details: error instanceof Error ? error.message : String(error) 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

