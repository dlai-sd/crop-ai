import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai/features/cloud_sync/models/cloud_sync_state.dart';
import 'package:crop_ai/features/cloud_sync/providers/cloud_sync_provider.dart';
import 'package:crop_ai/features/cloud_sync/presentation/widgets/sync_widgets.dart';

class AuthenticationScreen extends ConsumerStatefulWidget {
  const AuthenticationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends ConsumerState<AuthenticationScreen> {
  bool isSignUp = false;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isSignUp ? 'Sign Up' : 'Sign In')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            SizedBox(height: 40),
            Icon(Icons.cloud, size: 64, color: Colors.blue),
            SizedBox(height: 24),
            Text(
              'Crop AI',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Cloud Sync',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            SizedBox(height: 40),

            // Name field (Sign Up only)
            if (isSignUp) ...[
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Email field
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),

            // Password field
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),

            // Submit button
            ElevatedButton(
              onPressed: isLoading ? null : _handleSubmit,
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isSignUp ? 'Create Account' : 'Sign In'),
            ),
            SizedBox(height: 16),

            // Toggle button
            TextButton(
              onPressed: () {
                setState(() => isSignUp = !isSignUp);
                emailController.clear();
                passwordController.clear();
                nameController.clear();
              },
              child: Text(
                isSignUp ? 'Already have an account? Sign In' : 'Don\'t have an account? Sign Up',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isSignUp) {
        if (nameController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please enter your name')),
          );
          return;
        }

        final signUpUseCase = ref.read(signUpUseCaseProvider);
        await signUpUseCase(emailController.text, passwordController.text, nameController.text);
      } else {
        final signInUseCase = ref.read(signInUseCaseProvider);
        await signInUseCase(emailController.text, passwordController.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isSignUp ? 'Account created!' : 'Signed in successfully!')),
        );
        // Navigate to home screen
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }
}

class CloudSyncManagementScreen extends ConsumerStatefulWidget {
  final String userId;

  const CloudSyncManagementScreen({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<CloudSyncManagementScreen> createState() => _CloudSyncManagementScreenState();
}

class _CloudSyncManagementScreenState extends ConsumerState<CloudSyncManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final farmsAsync = ref.watch(userFarmsProvider(widget.userId));

    return Scaffold(
      appBar: SyncAppBar(title: Text('Cloud Sync Management')),
      body: farmsAsync.when(
        data: (farms) {
          if (farms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No farms synced yet'),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateFarmDialog(),
                    icon: Icon(Icons.add),
                    label: Text('Add Farm'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: farms.length,
            itemBuilder: (context, index) {
              final farm = farms[index];
              return _FarmSyncTile(farm: farm, userId: widget.userId);
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateFarmDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  void _showCreateFarmDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateFarmDialog(userId: widget.userId),
    );
  }
}

class _FarmSyncTile extends ConsumerWidget {
  final CloudFarm farm;
  final String userId;

  const _FarmSyncTile({required this.farm, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(syncStatisticsProvider(farm.id));

    return Card(
      margin: EdgeInsets.all(8),
      child: ExpansionTile(
        leading: Icon(Icons.agriculture),
        title: Text(farm.name),
        subtitle: Text(farm.location),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: statsAsync.when(
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SyncStatusIndicator(farmId: farm.id),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          final syncUseCase = ref.read(syncFarmUseCaseProvider);
                          syncUseCase(farm.id);
                        },
                        icon: Icon(Icons.sync),
                        label: Text('Sync Now'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => SyncProgressDialog(farmId: farm.id),
                        ),
                        icon: Icon(Icons.info),
                        label: Text('Details'),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateFarmDialog extends ConsumerStatefulWidget {
  final String userId;

  const _CreateFarmDialog({required this.userId});

  @override
  ConsumerState<_CreateFarmDialog> createState() => _CreateFarmDialogState();
}

class _CreateFarmDialogState extends ConsumerState<_CreateFarmDialog> {
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final areaController = TextEditingController();
  final cropController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create New Farm'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Farm Name'),
            ),
            TextField(
              controller: locationController,
              decoration: InputDecoration(labelText: 'Location'),
            ),
            TextField(
              controller: areaController,
              decoration: InputDecoration(labelText: 'Area (hectares)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: cropController,
              decoration: InputDecoration(labelText: 'Crop Type'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: isLoading ? null : _createFarm,
          child: isLoading ? CircularProgressIndicator() : Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createFarm() async {
    if (nameController.text.isEmpty ||
        locationController.text.isEmpty ||
        areaController.text.isEmpty ||
        cropController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final createFarmUseCase = ref.read(createFarmUseCaseProvider);
      await createFarmUseCase(
        userId: widget.userId,
        name: nameController.text,
        location: locationController.text,
        areaHectares: double.parse(areaController.text),
        cropType: cropController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Farm created and syncing...')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    areaController.dispose();
    cropController.dispose();
    super.dispose();
  }
}
