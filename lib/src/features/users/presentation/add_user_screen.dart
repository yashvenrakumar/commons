import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import 'add_user_controller.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _job = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _job.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ChangeNotifierProvider(
      create: (_) => AddUserController(
        repo: sl(),
        connectivity: sl(),
        syncService: sl(),
      ),
      child: Builder(
        builder: (context) {
          final c = context.watch<AddUserController>();
          return Scaffold(
            appBar: AppBar(title: const Text('Create User')),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.20),
                          cs.secondary.withValues(alpha: 0.14),
                        ],
                      ),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Create profile',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'This supports offline mode. If network is unavailable, sync will happen automatically.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 16),
                                _PremiumField(
                                  controller: _name,
                                  placeholder: 'First name',
                                  icon: CupertinoIcons.person_crop_circle,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 12),
                                _PremiumField(
                                  controller: _job,
                                  placeholder: 'Last name / job',
                                  icon: CupertinoIcons.briefcase,
                                  textInputAction: TextInputAction.done,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 18),
                                if (c.error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      c.error!,
                                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                                    ),
                                  ),
                                CupertinoButton.filled(
                                  borderRadius: BorderRadius.circular(14),
                                  onPressed: c.saving
                                      ? null
                                      : () async {
                                          if (!_formKey.currentState!.validate()) return;
                                          final id = await context.read<AddUserController>().createUser(
                                                name: _name.text.trim(),
                                                job: _job.text.trim(),
                                              );
                                          if (!context.mounted) return;
                                          if (id != null) Navigator.of(context).pop();
                                        },
                                  child: c.saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                                        )
                                      : const Text('Create User'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PremiumField extends StatelessWidget {
  const _PremiumField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    required this.validator,
    required this.textInputAction,
  });

  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      validator: validator,
      decoration: InputDecoration(
        hintText: placeholder,
        prefixIcon: Icon(icon, color: cs.primary),
      ),
    );
  }
}

