import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/google_logo.dart';
import '../controllers/auth_controller.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Get started',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Create your account to start calling',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.huge),

                  // Error
                  Obx(() {
                    if (controller.errorMessage.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              controller.errorMessage.value,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Name
                  AppTextField(
                    controller: nameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: Validators.validateName,
                    onChanged: (_) => controller.clearError(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Email
                  AppTextField(
                    controller: emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.validateEmail,
                    onChanged: (_) => controller.clearError(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Password
                  AppTextField(
                    controller: passwordController,
                    label: 'Password',
                    hint: 'Create a password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    showToggleVisibility: true,
                    textInputAction: TextInputAction.next,
                    validator: Validators.validatePassword,
                    onChanged: (_) => controller.clearError(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Confirm password
                  AppTextField(
                    controller: confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    showToggleVisibility: true,
                    textInputAction: TextInputAction.done,
                    validator: (value) => Validators.validateConfirmPassword(
                        value, passwordController.text),
                    onChanged: (_) => controller.clearError(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Register button
                  Obx(() => AppButton(
                        label: 'Create Account',
                        isLoading: controller.isLoading.value,
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            controller.register(
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                              password: passwordController.text,
                            );
                          }
                        },
                      )),

                  const SizedBox(height: AppSpacing.xxl),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Text(
                          'OR',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Google Sign-In button
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: (controller.isLoading.value ||
                                  controller.isGoogleLoading.value)
                              ? null
                              : () => controller.signInWithGoogle(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: controller.isGoogleLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GoogleLogo(),
                                    SizedBox(width: AppSpacing.md),
                                    Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      )),

                  const SizedBox(height: AppSpacing.xxl),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
