import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lionsns/l10n/app_localizations.dart';
import 'package:lionsns/features/auth/models/user.dart';
import 'package:lionsns/core/utils/result.dart';
import '../providers/providers.dart';

/// 로그인 화면
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    final authResult = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        // 다국어: 로그인 화면 제목
        title: Text(l10n.login),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // 로고 영역
              Icon(
                Icons.forum_outlined,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              // 다국어: 환영 메시지
              Text(
                l10n.welcomeMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 48),

              // SNS 로그인 버튼들
              _buildSnsLoginButtons(context, l10n),

              // 로딩 메시지 표시 (pending 상태일 때)
              authResult.when(
                success: (_) => const SizedBox.shrink(),
                failure: (_, __) => const SizedBox.shrink(),
                pending: (message) {
                  return Column(
                    children: [
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              // 다국어: 로그인 진행 중 메시지
                              child: Text(
                                message ?? l10n.loginInProgress,
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              // 에러 메시지 표시
              if (authResult is Failure) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (authResult as Failure<User?>).message,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSnsLoginButtons(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        // 다국어: Google 로그인 버튼
        _buildSnsButton(
          context,
          l10n.googleLogin,
          Icons.g_mobiledata,
          Colors.red,
              () => _handleSnsLogin(AuthProvider.google),
        ),
        const SizedBox(height: 12),
        // 다국어: Apple 로그인 버튼
        _buildSnsButton(
          context,
          l10n.appleLogin,
          Icons.apple,
          Colors.black,
              () => _handleSnsLogin(AuthProvider.apple),
        ),
        const SizedBox(height: 12),
        // 다국어: 카카오 로그인 버튼
        _buildSnsButton(
          context,
          l10n.kakaoLogin,
          Icons.chat,
          Colors.orange,
              () => _handleSnsLogin(AuthProvider.kakao),
        ),
        const SizedBox(height: 12),
        // 다국어: 네이버 로그인 버튼
        _buildSnsButton(
          context,
          l10n.naverLogin,
          Icons.public,
          Colors.green,
              () => _handleSnsLogin(AuthProvider.naver),
        ),
      ],
    );
  }

  Widget _buildSnsButton(
      BuildContext context,
      String text,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    final authResult = ref.watch(authViewModelProvider);
    final isLoading = authResult.when(
      success: (_) => false, // 로그인 성공/실패 상태에서는 버튼 활성화
      failure: (_, __) => false, // 실패 상태에서도 버튼 활성화
      pending: (_) => true, // pending 상태에서만 버튼 비활성화
    );

    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: Icon(icon, color: color),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  Future<void> _handleSnsLogin(AuthProvider provider) async {
    await ref.read(authViewModelProvider.notifier).signIn(provider);

    // 성공시 자동으로 홈으로 이동
    if (mounted) {
      final result = ref.read(authViewModelProvider);
      result.when(
        success: (user) {
          if (user != null) {
            context.go('/');
          }
        },
        failure: (message, error) {},
        pending: (message) {},
      );
    }
  }

  String _getProviderName(AuthProvider provider, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (provider) {
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.apple:
        return 'Apple';
      case AuthProvider.kakao:
        return l10n?.kakaoLogin ?? 'Kakao';
      case AuthProvider.naver:
        return l10n?.naverLogin ?? 'Naver';
    }
  }
}

