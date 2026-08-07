import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import 'support_profile_state.dart';

class UserProfileEditPage extends ConsumerStatefulWidget {
  const UserProfileEditPage({super.key});

  @override
  ConsumerState<UserProfileEditPage> createState() =>
      _UserProfileEditPageState();
}

class _UserProfileEditPageState extends ConsumerState<UserProfileEditPage> {
  late final TextEditingController _name;
  late final TextEditingController _tagline;
  late final TextEditingController _city;
  late final TextEditingController _lifeStage;
  late String _gender;
  late String _ageRange;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(supportProfileProvider);
    _name = TextEditingController(text: profile.preferredName);
    _tagline = TextEditingController(text: profile.personalTagline);
    _city = TextEditingController(text: profile.city);
    _lifeStage = TextEditingController(text: profile.lifeStage);
    _gender = profile.gender;
    _ageRange = profile.ageRange;
    _avatarBytes = profile.avatarBytes;
  }

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _city.dispose();
    _lifeStage.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1080,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) AppToast.show(context, '头像需小于 5MB');
      return;
    }
    setState(() => _avatarBytes = bytes);
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      AppToast.show(context, '请填写昵称');
      return;
    }
    ref.read(supportProfileProvider.notifier).savePublicProfile(
          preferredName: _name.text.trim(),
          personalTagline: _tagline.text.trim(),
          gender: _gender,
          ageRange: _ageRange,
          city: _city.text.trim(),
          lifeStage: _lifeStage.text.trim(),
          avatarBytes: _avatarBytes,
        );
    AppToast.show(context, '个人资料已更新');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: AppPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              const AppNavBar(
                  title: '编辑个人资料', transparent: true, lineHidden: true),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(24)),
                        child: Column(children: [
                          Stack(children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: colors.secondaryContainer,
                              backgroundImage: _avatarBytes == null
                                  ? null
                                  : MemoryImage(_avatarBytes!),
                              child: _avatarBytes == null
                                  ? const Icon(Icons.person_rounded, size: 46)
                                  : null,
                            ),
                            Positioned(
                                right: 0,
                                bottom: 0,
                                child: IconButton.filled(
                                    onPressed: _pickAvatar,
                                    icon: const Icon(
                                        Icons.photo_camera_outlined,
                                        size: 18))),
                          ]),
                          const SizedBox(height: 8),
                          TextButton(
                              onPressed: _pickAvatar,
                              child: const Text('更换头像')),
                          const SizedBox(height: 8),
                          _field('昵称', _name, hint: '希望大家怎么称呼你'),
                          _field('个人签名', _tagline,
                              hint: '一句话介绍当下的自己', maxLength: 40),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(24)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('基础信息',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text('用于个性化服务，不会直接对外公开。',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: colors.onSurfaceVariant)),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                  initialValue: _gender,
                                  decoration: const InputDecoration(
                                      labelText: '性别（可选）'),
                                  items: const ['不透露', '女', '男', '其他']
                                      .map((v) => DropdownMenuItem(
                                          value: v, child: Text(v)))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _gender = v!)),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                  initialValue: _ageRange,
                                  decoration:
                                      const InputDecoration(labelText: '年龄段'),
                                  items: const [
                                    '18–24 岁',
                                    '25–34 岁',
                                    '35–44 岁',
                                    '45–54 岁',
                                    '55 岁以上'
                                  ]
                                      .map((v) => DropdownMenuItem(
                                          value: v, child: Text(v)))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _ageRange = v!)),
                              const SizedBox(height: 14),
                              _field('常住城市', _city),
                              _field('职业 / 生活阶段（可选）', _lifeStage,
                                  hint: '例如：职场人士、学生、新手父母'),
                            ]),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: _save,
                              child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 13),
                                  child: Text('保存修改')))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
          {String? hint, int? maxLength}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
            controller: controller,
            maxLength: maxLength,
            decoration: InputDecoration(
                labelText: label, hintText: hint, counterText: '')),
      );
}
