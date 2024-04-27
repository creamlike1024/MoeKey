import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moekey/widgets/loading_weight.dart';
import 'package:moekey/widgets/mfm_text/mfm_text.dart';
import 'package:moekey/widgets/mk_image.dart';
import 'package:moekey/widgets/user_select_dialog/user_select_dialog_state.dart';

import '../../state/themes.dart';
import '../blur_widget.dart';
import '../input_decoration.dart';
import '../mk_card.dart';

class UserSelectDialog extends HookConsumerWidget {
  const UserSelectDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var queryPadding = MediaQuery.of(context).padding;
    var querySize = MediaQuery.of(context).size;
    var themes = ref.watch(themeColorsProvider);
    var userList = ref.watch(userSelectDialogStateProvider);
    var selectList = useState({});

    return LayoutBuilder(
      builder: (context, constraints) {
        var borderRadius = const BorderRadius.all(
          Radius.circular(12),
        );
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          behavior: HitTestBehavior.opaque,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Center(
                    // duration: const Duration(milliseconds: 500),
                    // top: isFullscreen ? 0 : 40,
                    child: GestureDetector(
                      onTap: () {},
                      child: AnimatedContainer(
                        width: querySize.width > 400 ? 400 : querySize.width,
                        height: querySize.height > 550
                            ? 550
                            : querySize.height - 32,
                        duration: const Duration(milliseconds: 500),
                        child: ClipRRect(
                          borderRadius: borderRadius,
                          child: MkCard(
                            padding: const EdgeInsets.all(0),
                            borderRadius: borderRadius,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    SizedBox(
                                      width: constraints.maxWidth,
                                      height: constraints.maxHeight,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            const SizedBox(height: 64),
                                            buildUserQuery(),
                                            const SizedBox(height: 8),
                                            for (var item
                                                in userList.valueOrNull ?? [])
                                              GestureDetector(
                                                onTap: () {
                                                  if (selectList.value
                                                      .containsKey(
                                                          item["id"])) {
                                                    selectList.value
                                                        .remove(item["id"]);
                                                  } else {
                                                    selectList
                                                            .value[item["id"]] =
                                                        item;
                                                  }

                                                  selectList.value = Map.from(
                                                      selectList.value);
                                                },
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                child: buildUserItem(
                                                    themes,
                                                    item,
                                                    selectList.value
                                                        .containsKey(
                                                            item["id"])),
                                              )
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      child: SizedBox(
                                        width: constraints.maxWidth,
                                        height: 50 + queryPadding.top,
                                        child: BlurWidget(
                                          color: themes.bgColor.withAlpha(204),
                                          child: Padding(
                                            padding: EdgeInsets.fromLTRB(
                                                0, queryPadding.top, 0, 0),
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                  border: Border(
                                                      bottom: BorderSide(
                                                          color: themes
                                                              .dividerColor,
                                                          width: 1))),
                                              child:
                                                  buildHeader(selectList.value),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildHeader(Map selectList) {
    return HookConsumer(
      builder: (context, ref, child) {
        var themes = ref.watch(themeColorsProvider);
        var data = ref.watch(userSelectDialogStateProvider);
        return Row(
          children: [
            const SizedBox(
              width: 4,
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                TablerIcons.x,
                size: 18,
                color: themes.fgColor,
              ),
            ),
            const SizedBox(
              width: 4,
            ),
            const Text("选择用户"),
            Text("(${selectList.length})"),
            const Spacer(),
            if (data.isLoading)
              const LoadingCircularProgress(
                size: 18,
                strokeWidth: 4,
              ),
            IconButton(
              onPressed: () {
                Navigator.of(context).pop(selectList.values);
              },
              icon: Icon(
                TablerIcons.check,
                size: 18,
                color: themes.fgColor,
              ),
            ),
            const SizedBox(
              width: 4,
            ),
          ],
        );
      },
    );
  }

  Widget buildUserQuery() {
    return HookConsumer(
      builder: (context, ref, child) {
        var themes = ref.watch(themeColorsProvider);
        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("用户名"),
                    const SizedBox(
                      height: 4,
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                          decoration: inputDecoration(
                            themes,
                            "",
                            prefixIcon: Icon(
                              TablerIcons.at,
                              color: themes.fgColor,
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                          cursorWidth: 1,
                          cursorColor: themes.fgColor,
                          maxLines: 1,
                          textAlignVertical: TextAlignVertical.center,
                          onChanged: (value) {
                            ref
                                .read(userSelectDialogStateProvider.notifier)
                                .search(name: value);
                          },
                          initialValue: "",
                        )),
                      ],
                    )
                  ],
                )),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("服务器"),
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                        children: [
                          Expanded(
                              child: TextFormField(
                            decoration: inputDecoration(
                              themes,
                              "",
                              prefixIcon:
                                  Icon(TablerIcons.at, color: themes.fgColor),
                            ),
                            style: const TextStyle(fontSize: 14),
                            cursorWidth: 1,
                            cursorColor: themes.fgColor,
                            maxLines: 1,
                            textAlignVertical: TextAlignVertical.center,
                            onChanged: (value) {
                              ref
                                  .read(userSelectDialogStateProvider.notifier)
                                  .search(host: value);
                            },
                            initialValue: "",
                          )),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ));
      },
    );
  }

  Widget buildUserItem(ThemeColorModel themes, item, isActive) {
    var name = item["name"] ?? item["username"] ?? "";
    var color = isActive ? themes.fgOnAccentColor : themes.fgColor;
    var style = TextStyle(color: color);
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: style,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isActive ? themes.accentColor : themes.panelColor,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: MkImage(
                item["avatarUrl"] ?? "",
                blurHash: item["avatarBlurhash"],
                width: 48,
                height: 48,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: style.copyWith(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    child: MFMText(
                      text: name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      bigEmojiCode: false,
                      feature: const [MFMFeature.emojiCode],
                    )),
                Builder(
                  builder: (context) {
                    return Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: "@${item["username"]}"),
                          if (item["host"] != null)
                            TextSpan(
                                text: "@${item["host"]}",
                                style: TextStyle(
                                    color: DefaultTextStyle.of(context)
                                        .style
                                        .color
                                        ?.withOpacity(0.6)))
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                )
              ],
            ))
          ],
        ),
      ),
    );
  }
}
