import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/app_widgets.dart';
import '../domain/promo_material.dart';
import 'promo_cubit.dart';

class PromoPage extends StatelessWidget {
  const PromoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PromoCubit, PromoState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<PromoCubit>().load(),
          child: ResponsiveCenter(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  sliver: _sliver(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sliver(BuildContext context, PromoState state) {
    return switch (state.status) {
      PromoStatus.loading => const SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingBlock(label: 'Loading promo materials'),
      ),
      PromoStatus.empty => const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.campaign_outlined,
          title: 'No promo materials',
          message: 'There is nothing to show for this language right now.',
        ),
      ),
      PromoStatus.failure => SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Promo materials unavailable',
          message: state.error ?? 'Please try again.',
          action: FilledButton(
            onPressed: () => context.read<PromoCubit>().load(),
            child: const Text('Try again'),
          ),
        ),
      ),
      PromoStatus.ready => SliverList.builder(
        itemCount: state.materials.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
            child: _PromoCard(material: state.materials[index]),
          );
        },
      ),
    };
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.material});

  final PromoMaterial material;

  @override
  Widget build(BuildContext context) {
    final imageUrl = material.imageUrl;
    final link = material.link;
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.network(
                imageUrl,
                height: 168,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                      child: Icon(Icons.image_not_supported_outlined),
                    ),
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 168,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (material.description != null) ...[
                  const SizedBox(height: 8),
                  Text(material.description!),
                ],
                if (link != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _openLink(context, link),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(material.actionLabel ?? 'Open'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      _tell(context, 'This promo link is not valid.');
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        _tell(context, "Couldn't open the link.");
      }
    } catch (_) {
      if (context.mounted) _tell(context, "Couldn't open the link.");
    }
  }

  void _tell(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
