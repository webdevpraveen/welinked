import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/features/pairing/presentation/providers/pairing_providers.dart';
import 'package:welinked/shared/widgets/loading_widget.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendRequest() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(pairingControllerProvider)
        .sendRequest(
          _emailController.text,
          onSuccess: () {
            _emailController.clear();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Duo request sent!')));
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActionLoading = ref.watch(pairingLoadingProvider);
    final incomingRequests = ref.watch(incomingRequestsProvider);
    final outgoingRequests = ref.watch(outgoingRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Connect with Duo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Send Connection Request',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter your Duo registered email address to send a link request.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Duo Email",
                          prefixIcon: Icon(Icons.person_add_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Enter Duo email";
                          }
                          if (!val.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isActionLoading ? null : _sendRequest,
                        child: isActionLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Send Link Request'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Incoming Requests',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            incomingRequests.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No pending requests. Ask your Duo to send a request.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return Card(
                      color: theme.colorScheme.surfaceContainer,
                      child: ListTile(
                        title: Text(req.fromName),
                        subtitle: Text(req.fromEmail),
                        trailing: ElevatedButton(
                          onPressed: isActionLoading
                              ? null
                              : () {
                                  ref
                                      .read(pairingControllerProvider)
                                      .acceptRequest(
                                        req,
                                        onSuccess: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Successfully paired!',
                                              ),
                                            ),
                                          );
                                        },
                                        onError: (error) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(error),
                                              backgroundColor:
                                                  theme.colorScheme.error,
                                            ),
                                          );
                                        },
                                      );
                                },
                          child: const Text('Accept'),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const AppLoadingWidget(),
              error: (err, stack) => Text('Error loading requests: $err'),
            ),
            const SizedBox(height: 24),
            Text(
              'Sent Requests',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            outgoingRequests.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No sent requests.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return Card(
                      color: theme.colorScheme.surfaceContainer,
                      child: ListTile(
                        title: Text(req.toEmail),
                        subtitle: const Text('Waiting for Duo to accept...'),
                        trailing: const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const AppLoadingWidget(),
              error: (err, stack) => Text('Error loading requests: $err'),
            ),
          ],
        ),
      ),
    );
  }
}
