import 'package:flutter/material.dart';
import 'package:lionsns/features/chat/models/chat_room.dart';

/// 채팅방 목록 아이템
class ChatRoomItem extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback onTap;

  const ChatRoomItem({
    super.key,
    required this.chatRoom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: chatRoom.otherUserImageUrl != null
            ? NetworkImage(chatRoom.otherUserImageUrl!)
            : null,
        child: chatRoom.otherUserImageUrl == null
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(
        chatRoom.otherUserName ?? '익명',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        chatRoom.lastMessage?.content ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: chatRoom.unreadCount != null && chatRoom.unreadCount! > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${chatRoom.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

