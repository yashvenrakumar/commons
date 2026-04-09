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
            appBar: AppBar(title: const Text('Create user')),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _job,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(labelText: 'Job'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      if (c.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            c.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      FilledButton(
                        onPressed: c.saving
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                final id = await context
                                    .read<AddUserController>()
                                    .createUser(
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
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Works offline. If offline, we’ll sync automatically when the network returns.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

