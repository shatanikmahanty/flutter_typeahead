import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_typeahead_example/product.dart';
import 'package:flutter_typeahead_example/options.dart';

typedef ProductController = ValueNotifier<Map<Product, int>>;

mixin SharedExampleTypeAheadConfig {
  FieldSettings get settings;
  ProductController get products;
  TextEditingController get controller;

  final String hintText = 'What are you looking for?';
  final BorderRadius borderRadius = BorderRadius.circular(10);
  void onSuggestionSelected(Product product) {
    products.value = Map.of(
      products.value
        ..update(
          product,
          (value) => value + 1,
          ifAbsent: () => 1,
        ),
    );
    controller.clear();
  }

  Future<List<Product>> suggestionsCallback(String pattern) async =>
      Future<List<Product>>.delayed(
        Duration(seconds: settings.loadingDelay.value ? 1 : 0),
        () => allProducts.where((product) {
          final nameLower = product.name.toLowerCase().split(' ').join('');
          final patternLower = pattern.toLowerCase().split(' ').join('');
          return nameLower.contains(patternLower);
        }).toList(),
      );

  Widget itemSeparatorBuilder(BuildContext context, int index) =>
      settings.dividers.value
          ? const Divider(height: 1)
          : const SizedBox.shrink();

  List<Widget> maybeReversed(List<Widget> children) {
    if (settings.direction.value == AxisDirection.up) {
      return children.reversed.toList();
    }
    return children;
  }

  Widget gridLayoutBuilder(
      Iterable<Widget> items, ScrollController controller) {
    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      shrinkWrap: true,
      primary: false,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 58,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) => items.toList()[index],
    );
  }

  Duration get debounceDuration => settings.debounce.value
      ? const Duration(milliseconds: 300)
      : Duration.zero;
}

class ExampleTypeAhead extends StatelessWidget
    with SharedExampleTypeAheadConfig {
  ExampleTypeAhead({
    super.key,
    required this.settings,
    required this.controller,
    required this.products,
  });

  @override
  final FieldSettings settings;
  @override
  final TextEditingController controller;
  @override
  final ProductController products;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: products,
      builder: (context, value, child) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: maybeReversed([
              TypeAheadFormField<Product>(
                direction: settings.direction.value,
                textFieldConfiguration: TextFieldConfiguration(
                  controller: controller,
                  autofocus: true,
                  style: DefaultTextStyle.of(context)
                      .style
                      .copyWith(fontStyle: FontStyle.italic),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: hintText,
                  ),
                ),
                suggestionsBoxDecoration: SuggestionsBoxDecoration(
                  borderRadius: borderRadius,
                  elevation: 8,
                  color: Theme.of(context).cardColor,
                ),
                itemBuilder: (context, product) => ListTile(
                  title: Text(product.name),
                  subtitle: product.description != null
                      ? Text(
                          '${product.description!} - \$${product.price}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text('\$${product.price}'),
                ),
                debounceDuration: debounceDuration,
                onSuggestionSelected: onSuggestionSelected,
                suggestionsCallback: suggestionsCallback,
                itemSeparatorBuilder: itemSeparatorBuilder,
                layoutArchitecture:
                    settings.gridLayout.value ? gridLayoutBuilder : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text('Shopping Cart',
                              style: Theme.of(context).textTheme.titleLarge),
                          const Spacer(),
                          Text(
                            'Total: \$${products.value.entries.fold<double>(
                                  0,
                                  (total, entry) =>
                                      total + entry.key.price * entry.value,
                                ).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: products.value.entries
                            .map(
                              (entry) => ListTile(
                                title: Text(entry.key.name),
                                subtitle: entry.key.description != null
                                    ? Text(entry.key.description!)
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'x${entry.value}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    Text(
                                      ', \$${entry.key.price * entry.value}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    IconButton(
                                      tooltip: 'Remove',
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      onPressed: () {
                                        products.value = Map.of(products.value)
                                          ..update(
                                            entry.key,
                                            (value) => value - 1,
                                            ifAbsent: () => 0,
                                          );
                                        if ((products.value[entry.key] ?? 0) <=
                                            0) {
                                          products.value =
                                              Map.of(products.value)
                                                ..remove(entry.key);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => products.value = {},
                    child: const Text('Checkout'),
                  ),
                ],
              ),
            ]),
          ),
        );
      },
    );
  }
}

class CupertinoExampleTypeAhead extends StatelessWidget
    with SharedExampleTypeAheadConfig {
  CupertinoExampleTypeAhead({
    super.key,
    required this.settings,
    required this.controller,
    required this.products,
  });

  @override
  final FieldSettings settings;
  @override
  final TextEditingController controller;
  @override
  final ProductController products;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: products,
      builder: (context, value, child) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: maybeReversed([
              CupertinoTypeAheadFormField<Product>(
                direction: settings.direction.value,
                textFieldConfiguration: CupertinoTextFieldConfiguration(
                  controller: controller,
                  autofocus: true,
                  style: DefaultTextStyle.of(context)
                      .style
                      .copyWith(fontStyle: FontStyle.italic),
                  decoration: BoxDecoration(
                    border: Border.all(color: CupertinoColors.inactiveGray),
                    borderRadius: borderRadius,
                  ),
                ),
                suggestionsBoxDecoration: CupertinoSuggestionsBoxDecoration(
                  borderRadius: borderRadius,
                  color: CupertinoColors.white,
                ),
                itemBuilder: (context, product) => CupertinoListTile(
                  title: Text(product.name),
                  subtitle: product.description != null
                      ? Text(
                          '${product.description!} - \$${product.price}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text('\$${product.price}'),
                ),
                onSuggestionSelected: onSuggestionSelected,
                suggestionsCallback: suggestionsCallback,
                itemSeparatorBuilder: itemSeparatorBuilder,
                layoutArchitecture:
                    settings.gridLayout.value ? gridLayoutBuilder : null,
                debounceDuration: debounceDuration,
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('Shopping Cart',
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .copyWith(fontSize: 24)),
                    const Spacer(),
                    Text(
                      'Total: \$${products.value.entries.fold<double>(
                            0,
                            (total, entry) =>
                                total + entry.key.price * entry.value,
                          ).toStringAsFixed(2)}',
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .textStyle
                          .copyWith(fontSize: 18),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: products.value.entries
                      .map(
                        (entry) => CupertinoListTile(
                          title: Text(entry.key.name),
                          subtitle: entry.key.description != null
                              ? Text(entry.key.description!)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'x${entry.value}',
                                style: CupertinoTheme.of(context)
                                    .textTheme
                                    .textStyle
                                    .copyWith(fontSize: 18),
                              ),
                              Text(
                                ', \$${entry.key.price * entry.value}',
                                style: CupertinoTheme.of(context)
                                    .textTheme
                                    .textStyle
                                    .copyWith(fontSize: 18),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  products.value = Map.of(products.value)
                                    ..update(
                                      entry.key,
                                      (value) => value - 1,
                                      ifAbsent: () => 0,
                                    );
                                  if ((products.value[entry.key] ?? 0) <= 0) {
                                    products.value = Map.of(products.value)
                                      ..remove(entry.key);
                                  }
                                },
                                child: const Icon(
                                  CupertinoIcons.minus_circled,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    onPressed: () => products.value = {},
                    child: const Text('Checkout'),
                  ),
                ],
              ),
            ]),
          ),
        );
      },
    );
  }
}