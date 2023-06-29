import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lemmy_api_client/v3.dart';
import 'package:thunder/community/widgets/post_card_list.dart';

import 'package:thunder/core/models/comment_view_tree.dart';
import 'package:thunder/core/models/post_view_media.dart';
import 'package:thunder/post/widgets/comment_view.dart';
import 'package:thunder/user/bloc/user_bloc.dart';
import 'package:thunder/utils/date_time.dart';

const List<Widget> userOptionTypes = <Widget>[
  Padding(padding: EdgeInsets.all(8.0), child: Text('Posts')),
  Padding(padding: EdgeInsets.all(8.0), child: Text('Comments')),
];

class UserPageSuccess extends StatefulWidget {
  final int? userId;

  final PersonViewSafe? personView;
  final List<CommentViewTree>? comments;
  final List<PostViewMedia>? posts;

  final bool hasReachedPostEnd;
  final bool hasReachedCommentEnd;

  const UserPageSuccess({
    super.key,
    this.userId,
    this.personView,
    this.comments,
    this.posts,
    this.hasReachedPostEnd = false,
    this.hasReachedCommentEnd = false,
  });

  @override
  State<UserPageSuccess> createState() => _UserPageSuccessState();
}

class _UserPageSuccessState extends State<UserPageSuccess> {
  int selectedUserOption = 0;
  final List<bool> _selectedUserOption = <bool>[true, false];
  final _scrollController = ScrollController(initialScrollOffset: 0);

  @override
  void initState() {
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      context.read<UserBloc>().add(const GetUserEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(widget.personView?.person.name ?? 'N/A', style: Theme.of(context).textTheme.titleMedium),
          Text(formatTimeToString(dateTime: widget.personView!.person.published.toIso8601String()), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12.0),
          ToggleButtons(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            direction: Axis.horizontal,
            onPressed: (int index) {
              setState(() {
                // The button that is tapped is set to true, and the others to false.
                for (int i = 0; i < _selectedUserOption.length; i++) {
                  _selectedUserOption[i] = i == index;
                }
                selectedUserOption = index;
              });
            },
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            constraints: BoxConstraints.expand(width: (MediaQuery.of(context).size.width / userOptionTypes.length) - 12.0),
            isSelected: _selectedUserOption,
            children: userOptionTypes,
          ),
          const SizedBox(height: 12.0),
          Expanded(
            child: selectedUserOption == 0
                ? PostCardList(
                    postViews: widget.posts,
                    personId: widget.userId,
                    hasReachedEnd: widget.hasReachedPostEnd,
                    onScrollEndReached: () => context.read<UserBloc>().add(const GetUserEvent()),
                    onSaveAction: (int postId, bool save) => context.read<UserBloc>().add(SavePostEvent(postId: postId, save: save)),
                    onVoteAction: (int postId, VoteType voteType) => context.read<UserBloc>().add(VotePostEvent(postId: postId, score: voteType)),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    child: CommentSubview(comments: widget.comments ?? []),
                  ),
          ),
        ],
      ),
    );
  }
}