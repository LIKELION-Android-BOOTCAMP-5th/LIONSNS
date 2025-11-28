// Supabase Edge Function: 좋아요 시 알림 전송
// 게시글에 좋아요가 추가되면 게시글 작성자에게 푸시 알림을 전송합니다.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface LikeNotificationRequest {
  postId: string
  likerId: string
  postAuthorId: string
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
    const { postId, likerId, postAuthorId }: LikeNotificationRequest = await req.json()

    if (!postId || !likerId || !postAuthorId) {
      return new Response(
        JSON.stringify({ error: 'postId, likerId, postAuthorId는 필수입니다' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 자신의 게시글에 좋아요를 단 경우 알림 전송하지 않음
    if (likerId === postAuthorId) {
      return new Response(
        JSON.stringify({ message: '자신의 게시글에 좋아요를 단 경우 알림을 전송하지 않습니다' }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Supabase 클라이언트 생성
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // 좋아요한 사용자 정보 조회
    const { data: liker, error: likerError } = await supabase
      .from('user_profiles')
      .select('name')
      .eq('id', likerId)
      .single()

    if (likerError || !liker) {
      console.error('좋아요한 사용자 정보 조회 실패:', likerError)
      // 사용자 정보가 없어도 알림은 전송
    }

    // 게시글 정보 조회
    const { data: post, error: postError } = await supabase
      .from('posts')
      .select('content')
      .eq('id', postId)
      .single()

    if (postError || !post) {
      console.error('게시글 정보 조회 실패:', postError)
    }

    // 좋아요 개수 조회
    const { count: likeCount, error: countError } = await supabase
      .from('post_likes')
      .select('*', { count: 'exact', head: true })
      .eq('post_id', postId)

    if (countError) {
      console.error('좋아요 개수 조회 실패:', countError)
    }

    // 알림 제목 및 내용 구성
    const likerName = liker?.name || '누군가'
    const title = '게시글에 좋아요가 추가되었습니다'
    const body = likeCount && likeCount > 1
      ? `${likerName}님 외 ${likeCount - 1}명이 좋아요를 눌렀습니다`
      : `${likerName}님이 좋아요를 눌렀습니다`

    // send-push-notification 함수 호출
    const functionUrl = `${SUPABASE_URL}/functions/v1/send-push-notification`
    const functionResponse = await fetch(functionUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        userId: postAuthorId,
        title: title,
        body: body,
        data: {
          type: 'like',
          postId: postId,
          likerId: likerId,
          likeCount: likeCount || 1,
        },
      }),
    })

    if (!functionResponse.ok) {
      const errorText = await functionResponse.text()
      throw new Error(`푸시 알림 전송 실패: ${functionResponse.status} - ${errorText}`)
    }

    const result = await functionResponse.json()

    return new Response(
      JSON.stringify({
        success: true,
        message: '좋아요 알림 전송 완료',
        result: result,
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  } catch (error) {
    console.error('좋아요 알림 전송 실패:', error)
    return new Response(
      JSON.stringify({ 
        error: '좋아요 알림 전송 실패', 
        details: error instanceof Error ? error.message : String(error) 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

