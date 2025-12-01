import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../viewmodels/room_detail_view_model.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../widgets/home_header.dart';
import 'update_room_screen.dart';
import '../widgets/invitation_drawer.dart';
import '../widgets/people_card.dart';
import 'trip_schedule_screen.dart'; // 경로 변경
import '../config/app_config.dart'; // Import the new config file
import '../widgets/checklist_card.dart'; // 체크리스트 카드 임포트

class RoomDetailScreen extends StatelessWidget {
  final String roomId;
  final String userId;
  final String nickname;
  final String id;

  Future<void> _deleteRoom(
    BuildContext context,
    RoomDetailViewModel viewModel,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('여행방 삭제'),
        content: const Text('정말로 이 여행방을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await viewModel.deleteRoom(); // bool 반환
      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('여행방이 삭제되었습니다.')));
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {'userId': userId, 'nickname': nickname, 'id': id},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.errorMessage ?? '삭제에 실패했습니다.')),
        );
      }
    }
  }

  const RoomDetailScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.nickname,
    required this.id,
  });

  String _calculateDuration(String startDateStr, String endDateStr) {
    try {
      final startDate = DateTime.parse(startDateStr);
      final endDate = DateTime.parse(endDateStr);
      final difference = endDate.difference(startDate).inDays;
      if (difference < 0) {
        return '기간 오류';
      }
      return '$difference박 ${difference + 1}일';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          RoomDetailViewModel(roomId: roomId, currentUserId: id)
            ..fetchAllDetails(),
      child: Scaffold(
        endDrawer: InvitationDrawer(
          userId: userId,
          onInvitationHandled: () {
            // Using context.read to call a method on the ViewModel
            // without rebuilding the widget.
            context.read<RoomDetailViewModel>().fetchAllDetails();
          },
        ),
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              HomeHeader(
                userId: userId,
                nickname: nickname,
                id: id,
                onLogoTap: () => Navigator.pushNamedAndRemoveUntil(
                  // 로고 탭 시 홈으로 이동
                  context,
                  '/home',
                  (route) => false,
                  arguments: {'userId': userId, 'nickname': nickname, 'id': id},
                ),
              ),
              Expanded(
                child: Consumer<RoomDetailViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (viewModel.roomDetails == null) {
                      return const Center(child: Text('여행방 정보를 불러올 수 없습니다.'));
                    } else {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 상단 이미지 배너
                            if (viewModel.roomDetails?.imageId != null)
                              SizedBox(
                                height: 250,
                                width: double.infinity,
                                child: Image.network(
                                  '$kBaseUrl/api/images/${viewModel.roomDetails!.imageId!}', // kBaseUrl 사용
                                  fit: BoxFit.cover,
                                ),
                              ),
                            // 정보 카드 섹션
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoCard(context, viewModel),
                                  const SizedBox(height: 20),
                                  _buildPeopleCard(context, viewModel),
                                  const SizedBox(height: 20),
                                  ChecklistCard(roomId: roomId),
                                  const SizedBox(height: 40),
                                  if (viewModel.isOwner)
                                    Center(
                                      child: TextButton(
                                        onPressed: () =>
                                            _deleteRoom(context, viewModel),
                                        child: const Text(
                                          '여행방 삭제',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCard(
    BuildContext context, {
    required String title,
    required Widget child,
    VoidCallback? onEdit,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFF6000), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6000),
                  ),
                ),
                // 방장에게만 수정 버튼이 보이도록 처리
                if (onEdit != null &&
                    context.read<RoomDetailViewModel>().isOwner)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, RoomDetailViewModel viewModel) {
    final room = viewModel.roomDetails!;
    return _buildCustomCard(
      context,
      title: 'INFO',
      onEdit: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UpdateRoomScreen(
              userId: userId,
              nickname: nickname,
              id: id,
              roomId: roomId,
              roomDetails: room.toJson(),
            ),
          ),
        ).then((result) {
          // 수정 화면에서 돌아왔을 때 데이터 새로고침
          if (result == true) {
            viewModel.fetchAllDetails();
          }
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽 정보 영역 (제목, 국가)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      '여행 국가',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const Text(
                      ' | ',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Text(
                      room.country,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 오른쪽 기간 정보 영역
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                '${DateFormat('yyyy.MM.dd').format(room.startDate)} ~ ${DateFormat('yyyy.MM.dd').format(room.endDate)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                _calculateDuration(
                  room.startDate.toIso8601String(),
                  room.endDate.toIso8601String(),
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleCard(BuildContext context, RoomDetailViewModel viewModel) {
    final room = viewModel.roomDetails!;
    return PeopleCard(
      roomId: room.id,
      currentUserId: id, // DB의 _id를 전달하여 ownerId와 비교
      ownerLoginId: "TBD", // ownerLoginId is not in the model
      ownerId: room.creatorId,
      members: viewModel.members,
      onMembersChanged: () => viewModel.fetchAllDetails(),
    );
  }

  Widget _buildBottomNavBar(
    BuildContext context,
    RoomDetailViewModel viewModel,
  ) {
    final viewModel = context.read<RoomDetailViewModel>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFF6000),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined),
              color: Colors.white,
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                  arguments: {'userId': userId, 'nickname': nickname, 'id': id},
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.info), // 현재 화면 아이콘
              color: Colors.white,
              onPressed: () {
                // 현재 화면이므로 동작 없음
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today_outlined),
              color: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TripScheduleScreen(
                      roomId: roomId,
                      startDate: viewModel.roomDetails!.startDate
                          .toIso8601String(),
                      endDate: viewModel.roomDetails!.endDate.toIso8601String(),
                      userId: userId,
                      nickname: nickname,
                      id: id,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
