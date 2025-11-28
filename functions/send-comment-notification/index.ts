// Supabase Edge Function: 댓글 작성 시 알림 전송
// 댓글이 작성되면 게시글 작성자에게 푸시 알림을 전송합니다.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface CommentNotificationRequest {
  postId: string
  commentId: string
  commenterId: string
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
    const { postId, commentId, commenterId, postAuthorId }: CommentNotificationRequest = await req.json()

    if (!postId || !commentId || !commenterId || !postAuthorId) {
      return new Response(
        JSON.stringify({ error: 'postId, commentId, commenterId, postAuthorId는 필수입니다' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 자신의 게시글에 댓글을 단 경우 알림 전송하지 않음
    if (commenterId === postAuthorId) {
      return new Response(
        JSON.stringify({ message: '자신의 게시글에 댓글을 단 경우 알림을 전송하지 않습니다' }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Supabase 클라이언트 생성
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // 댓글 작성자 정보 조회
    const { data: commenter, error: commenterError } = await supabase
      .from('user_profiles')
      .select('name')
      .eq('id', commenterId)
      .single()

    if (commenterError || !commenter) {
      console.error('댓글 작성자 정보 조회 실패:', commenterError)
      // 댓글 작성자 정보가 없어도 알림은 전송
    }

    // 게시글 정보 조회 (제목 등)
    const { data: post, error: postError } = await supabase
      .from('posts')
      .select('content')
      .eq('id', postId)
      .single()

    if (postError || !post) {
      console.error('게시글 정보 조회 실패:', postError)
    }

    // 알림 제목 및 내용 구성
    const commenterName = commenter?.name || '누군가'
    const postPreview = post?.content 
      ? (post.content.length > 50 ? post.content.substring(0, 50) + '...' : post.content)
      : '게시글'

    const title = '새로운 댓글이 달렸습니다'
    const body = `${commenterName}님이 댓글을 남겼습니다: ${postPreview}`

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
          type: 'comment',
          postId: postId,
          commentId: commentId,
          commenterId: commenterId,
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
        message: '댓글 알림 전송 완료',
        result: result,
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  } catch (error) {
    console.error('댓글 알림 전송 실패:', error)
    return new Response(
      JSON.stringify({ 
        error: '댓글 알림 전송 실패', 
        details: error instanceof Error ? error.message : String(error) 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

