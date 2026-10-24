import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:xml/xml.dart';

import '../../../core/config/api_config.dart';

class PromoMaterial extends Equatable {
  const PromoMaterial({
    required this.title,
    this.description,
    this.imageUrl,
    this.link,
    this.actionLabel,
  });

  final String title;
  final String? description;
  final String? imageUrl;
  final String? link;
  final String? actionLabel;

  @override
  List<Object?> get props => [title, description, imageUrl, link, actionLabel];
}

class PromoEnvelope {
  const PromoEnvelope({required this.items, this.fault});

  final List<PromoMaterial> items;
  final String? fault;

  bool get hasFault => fault != null && fault!.trim().isNotEmpty;
}

PromoEnvelope parsePromoEnvelope(String raw) {
  final document = XmlDocument.parse(raw.trim());
  final elements = document.descendants.whereType<XmlElement>().toList();
  final faults = elements.where(
    (element) => element.name.local.toLowerCase() == 'fault',
  );
  if (faults.isNotEmpty) {
    final message = faults.first.descendants
        .whereType<XmlElement>()
        .where((element) {
          final name = element.name.local.toLowerCase();
          return name == 'faultstring' || name == 'text' || name == 'reason';
        })
        .map((element) => element.innerText.trim())
        .where((text) => text.isNotEmpty)
        .join(' ');
    return PromoEnvelope(
      items: const [],
      fault: message.isEmpty
          ? 'Promo materials are temporarily unavailable.'
          : message,
    );
  }

  final embedded = elements.where(
    (element) => element.name.local == 'GetCCPromoResult',
  );
  if (embedded.isNotEmpty) {
    final fromJson = parsePromoPayload(embedded.first.innerText);
    if (fromJson.isNotEmpty) return PromoEnvelope(items: fromJson);
  }

  final items = elements
      .where(_looksLikeItem)
      .where((element) => !element.childElements.any(_looksLikeItem))
      .map(_toPromo)
      .where(
        (promo) =>
            promo.title.isNotEmpty ||
            promo.imageUrl != null ||
            promo.link != null,
      )
      .toList();
  return PromoEnvelope(items: items);
}

List<PromoMaterial> parsePromoPayload(String raw) {
  var text = raw.trim();
  if (text.isEmpty || !text.startsWith('{')) return const [];
  text = text
      .replaceAll(RegExp(r'\bFalse\b'), 'false')
      .replaceAll(RegExp(r'\bTrue\b'), 'true');
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    return const [];
  }
  if (decoded is! Map) return const [];
  final items = <PromoMaterial>[];
  for (final entry in decoded.entries) {
    if (entry.value is! Map) continue;
    final fields = (entry.value as Map).map(
      (key, value) => MapEntry('$key', value),
    );
    final description = _asText(fields['text']);
    final action = _asText(fields['button_text']);
    items.add(
      PromoMaterial(
        title: _titleFromKey('${entry.key}', fallback: action ?? description),
        description: description,
        imageUrl: rewritePromoImageUrl(_asText(fields['image'])),
        link: _asText(fields['link']),
        actionLabel: action,
      ),
    );
  }
  return items;
}

String _titleFromKey(String key, {String? fallback}) {
  final words = key
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
  if (words.isNotEmpty) return words;
  return fallback ?? 'Promo';
}

String? _asText(Object? value) {
  if (value == null) return null;
  final text = '$value'.trim();
  if (text.isEmpty || text == 'null') return null;
  return text;
}

String? rewritePromoImageUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  final rewritten = trimmed.replaceAll(
    ApiConfig.legacyImageHost,
    ApiConfig.imageHost,
  );
  return rewritten.replaceFirst(
    'http://${ApiConfig.imageHost}',
    'https://${ApiConfig.imageHost}',
  );
}

bool _looksLikeItem(XmlElement element) {
  final names = element.childElements
      .map((child) => child.name.local.toLowerCase())
      .toSet();
  final hasTitle = names.any(
    (name) =>
        name.contains('title') || name == 'name' || name.contains('caption'),
  );
  final hasImage = names.any(
    (name) =>
        name.contains('image') ||
        name.contains('img') ||
        name.contains('banner') ||
        name.contains('picture'),
  );
  final hasLink = names.any(
    (name) =>
        name.contains('link') || name.contains('url') || name.contains('href'),
  );
  return (hasTitle && (hasImage || hasLink)) || (hasImage && hasLink);
}

PromoMaterial _toPromo(XmlElement element) {
  String? child(bool Function(String name) match) {
    for (final node in element.childElements) {
      if (match(node.name.local.toLowerCase())) {
        final text = node.innerText.trim();
        if (text.isNotEmpty) return text;
      }
    }
    return null;
  }

  final title =
      child(
        (name) =>
            name.contains('title') ||
            name == 'name' ||
            name.contains('caption'),
      ) ??
      'Promo';
  return PromoMaterial(
    title: title,
    description: child(
      (name) =>
          name.contains('description') ||
          name == 'text' ||
          name == 'body' ||
          name.contains('comment'),
    ),
    imageUrl: rewritePromoImageUrl(
      child(
        (name) =>
            name.contains('image') ||
            name.contains('img') ||
            name.contains('banner') ||
            name.contains('picture'),
      ),
    ),
    link: child(
      (name) =>
          name.contains('link') ||
          name.contains('url') ||
          name.contains('href'),
    ),
  );
}
