import 'dart:async';

import 'package:moekey/status/timeline.dart';
import 'package:moekey/status/websocket.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../apis/models/note.dart';
import '../main.dart';
import 'dio.dart';
import 'misskey_api.dart';
import 'server.dart';

part 'notes.g.dart';

@riverpod
class Notes extends _$Notes {
  @override
  FutureOr<NotesState> build(String noteId) async {
    var apis = await ref.watch(misskeyApisProvider.future);
    var data = await apis.notes.show(noteId: noteId);
    var noteTranslate = ref.read(noteListProvider)[noteId]?.noteTranslate;
    data?.noteTranslate = noteTranslate;
    var note = NotesState();
    ref
        .read(noteListProvider.notifier)
        .registerNote(data!, notUpdateReplyAndRenote: true);
    note.data = data;
    if (data.reply != null) {
      note.conversation.add(data.reply!);
    }
    return note;
  }

  ///notes/conversation
  loadConversation() async {
    var http = await ref.read(httpProvider.future);
    var user = await ref.read(currentLoginUserProvider.future);
    if (state.valueOrNull!.conversation.firstOrNull?.id == null) return;
    var data = await http.post(
      "/notes/conversation",
      data: {
        "i": user!.token,
        "noteId": state.valueOrNull!.conversation.firstOrNull!.id,
      },
    );
    List<NoteModel> list = [];
    for (var item in data.data.reversed) {
      list.add(NoteModel.fromMap(item));
    }
    state.value?.conversation = list + state.value!.conversation;
    return AsyncData(state.value);
  }
}

@Riverpod(keepAlive: true)
class NotesListener extends _$NotesListener {
  Map<String, Map<String, dynamic>> noteList = {};
  StreamSubscription<MoekeyEvent>? listen;

  @override
  Future build() async {
    try {
      ref.onDispose(() {
        logger.d("========= NotesListener dispose ===================");
        listen?.cancel();
        listen = null;
      });
      var user = await ref.watch(currentLoginUserProvider.future);
      listen?.cancel();
      listen = null;
      listen = moekeyStreamController.stream.listen((event) async {
        if (event.type == MoekeyEventType.data) {
          if (event.data["type"] == "noteUpdated") {
            var eventData = event.data;
            logger.d(eventData);
            var noteId = eventData["body"]["id"];
            var type = eventData["body"]["type"];
            var note = ref.read(noteListProvider)[noteId];
            if (note != null) {
              var data = note.copyWith();
              // logger.d(data);
              // logger.d(event.data);
              // 反应
              var reactions = data.reactions;
              if (type == "reacted") {
                var reaction = eventData["body"]["body"]["reaction"];
                var userId = eventData["body"]["body"]["userId"];
                var emoji = eventData["body"]["body"]["emoji"];
                if (reactions[reaction] == null) {
                  reactions[reaction] = 0;
                }
                reactions[reaction] = reactions[reaction]! + 1;
                if (emoji != null) {
                  data.reactionEmojis[emoji["name"]] = emoji["url"];
                }
                // 处理用户
                if (userId == user?.id) {
                  data.myReaction = reaction;
                }
              }
              // 取消反应
              if (type == "unreacted") {
                var reaction = eventData["body"]["body"]["reaction"];
                var userId = eventData["body"]["body"]["userId"];
                if (reactions[reaction] != null) {
                  reactions[reaction] = reactions[reaction]! - 1;
                  if (reactions[reaction]! <= 0) {
                    reactions.remove(reaction);
                  }
                }

                // 处理用户
                if (userId == user?.id) {
                  data.myReaction = null;
                }
              }
              // logger.d(data.hashCode);
              ref
                  .read(noteListProvider.notifier)
                  .registerNote(data, notUpdateReplyAndRenote: true);
            }
          }
        }
        if (event.type == MoekeyEventType.load) {
          logger.d("========= NotesListener load ===================");
          logger.d(noteList);
          for (var item in noteList.entries) {
            if (item.value.isNotEmpty) {
              _s(item.key);
            }
          }
        }
      });
      for (var item in noteList.entries) {
        if (item.value.isNotEmpty) {
          _s(item.key);
        }
      }
    } catch (e) {
      logger.d(e);
    }
  }

  _s(String id) {
    ref.read(moekeyGlobalEventProvider.notifier).send({
      "type": "s",
      "body": {"id": id}
    });
  }

  _un(String id) {
    ref.read(moekeyGlobalEventProvider.notifier).send({
      "type": "un",
      "body": {"id": id}
    });
  }

  subNote(NoteModel data, String id) {
    if (noteList[data.id] == null) {
      noteList[data.id] = {};
    }
    if (noteList[data.id]![id] == null) {
      noteList[data.id]![id] = true;
      _s(data.id);
    }
  }

  unsubNote(NoteModel data, String id) {
    if (noteList[data.id] == null) {
      _un(data.id);
      return;
    }

    noteList[data.id]?.remove(id);

    if (noteList[data.id]!.isEmpty) {
      _un(data.id);
    }
  }
}

class NotesState {
  late NoteModel data;
  List<NoteModel> conversation = [];
}

@riverpod
class NotesChildTimeline extends _$NotesChildTimeline {
  @override
  FutureOr<List> build(String noteId) async {
    List<NoteModel> list = await getRepliesList(id: noteId);
    Map<String, List<NoteModel>> map = {};
    for (var item in list) {
      var id = item.replyId ?? noteId;
      if (map[id] == null) {
        map[id] = [];
      }
      map[id]!.add(item);
    }
    List<List<NoteModel>> list1 = [];
    // 遍历一级回复
    for (NoteModel item in map[noteId] ?? []) {
      List<NoteModel> list2 = [item];
      var tmp = getRepliesListByMap(id: item.id, map: map);

      tmp.sort((obj1, obj2) {
        int t = obj1.createdAt.compareTo(obj2.createdAt);
        return t;
      });
      list2.addAll(tmp);
      list1.add(list2);
    }
    list1.sort((obj1, obj2) {
      int t = obj2[0].createdAt.compareTo(obj1[0].createdAt);
      return t;
    });
    for (var item in list1) {
      for (var item1 in item) {
        ref
            .read(noteListProvider.notifier)
            .registerNote(item1, notUpdateReplyAndRenote: true);
      }
    }
    return list1;
  }

  List<NoteModel> getRepliesListByMap(
      {required String id, required Map<String, List<NoteModel>> map}) {
    List<NoteModel> list = [];
    for (NoteModel item in map[id] ?? []) {
      list.add(item);
      var res1 = getRepliesListByMap(id: item.id, map: map);
      list.addAll(res1);
    }
    return list;
  }

  Future<List<NoteModel>> getRepliesList({
    required String id,
    int maxCount = 10,
  }) async {
    if (maxCount <= 0) return [];
    List<NoteModel> list = [];
    List<NoteModel> res = await getData(id: id);
    for (var item in res) {
      list.add(item);
      // if (item["repliesCount"] != null && item["repliesCount"] != 0) {
      var res1 = await getRepliesList(id: item.id, maxCount: maxCount - 1);
      list.addAll(res1);
      // }
    }
    return list;
  }

  Future<List<NoteModel>> getData(
      {required String id, int? limit, String? untilId}) async {
    var apis = await ref.read(misskeyApisProvider.future);

    var data = await apis.notes
        .children(noteId: noteId, untilId: untilId, limit: limit ?? 30);

    return data;
  }
}