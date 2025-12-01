import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/room_model.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/home_header.dart';
import '../widgets/invitation_drawer.dart';

class HomeScreen extends StatefulWidget {
  final String userId; // 로그인 후 전달받는 사용자 ID
  final String nickname;
  final String id;
  const HomeScreen({
    super.key,
    required this.userId,
    required this.nickname,
    required this.id,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel;

  String _sortOption = '최신순';
  final List<String> _sortOptions = ['최신순', '오래된 순', '가나다 순'];

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(userId: widget.userId);
    _viewModel.addListener(_onViewModelUpdated);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdated);
    super.dispose();
  }

  void _onViewModelUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  // D-Day 상태를 계산하고 스타일을 결정하는 위젯 생성
  Widget _buildDdayStatus(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String statusText;
    Color backgroundColor;
    Color textColor;

    if (today.isBefore(startDate)) {
      final difference = startDate.difference(today).inDays;
      statusText = 'D-$difference';
      backgroundColor = const Color(0xFFFFEFE5);
      textColor = const Color(0xFFFF6000);
    } else if (today.isAfter(endDate)) {
      statusText = '여행 종료';
      backgroundColor = Colors.grey.shade200;
      textColor = Colors.grey.shade600;
    } else {
      statusText = '여행 중';
      backgroundColor = Colors.blue.shade100;
      textColor = Colors.blue.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: InvitationDrawer(
        userId: widget.userId, // ViewModel을 통해 초대 목록을 가져오도록 수정 필요
        onInvitationHandled: () => _viewModel.fetchAllData(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              userId: widget.userId,
              nickname: widget.nickname,
              id: widget.id,
              onLogoTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                  arguments: {
                    'userId': widget.userId,
                    'nickname': widget.nickname,
                    'id': widget.id,
                  },
                );
              },
            ),

            // 정렬 옵션 드롭다운
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.sort, color: Color(0xFFFF6000)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sortOption,
                    items: _sortOptions
                        .map(
                          (opt) =>
                              DropdownMenuItem(value: opt, child: Text(opt)),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _sortOption = val!;
                        // ViewModel에서 정렬 로직 수행하도록 수정 필요
                      });
                    },
                  ),
                ],
              ),
            ),

            // 여행방 리스트
            Expanded(
              child: _viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _viewModel.rooms.isEmpty
                  ? const Center(child: Text('참여 중인 여행방이 없습니다.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _viewModel.rooms.length,
                      itemBuilder: (context, index) {
                        // 정렬 로직
                        final sortedRooms = List<Room>.from(_viewModel.rooms);
                        sortedRooms.sort((a, b) {
                          if (_sortOption == '최신순') {
                            return b.createdAt.compareTo(a.createdAt);
                          } else if (_sortOption == '오래된 순') {
                            return a.createdAt.compareTo(b.createdAt);
                          } else if (_sortOption == '가나다 순') {
                            return a.title.compareTo(b.title);
                          }
                          return 0;
                        });

                        final room = sortedRooms[index];
                        return _buildTravelRoomCard(room);
                      },
                    ),
            ),

            // 하단 네비게이션 바
            Padding(
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
                      icon: const Icon(Icons.home),
                      color: Colors.white,
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_box),
                      color: Colors.white,
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/add_room',
                          arguments: {
                            'userId': widget.userId,
                            'nickname': widget.nickname,
                            'id': widget.id,
                          },
                        );
                        // 방 생성이 완료되면 목록을 새로고침
                        if (result == true) _viewModel.fetchRooms();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person),
                      color: Colors.white,
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/account',
                          arguments: {'userId': widget.userId, 'id': widget.id},
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelRoomCard(Room room) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/room_detail',
          arguments: {
            'roomId': room.id,
            'userId': widget.userId,
            'nickname': widget.nickname,
            'id': widget.id,
          },
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFF6000), width: 1),
        ),
        color: Colors.white,
        clipBehavior: Clip.antiAlias, // 이미지가 카드 밖으로 나가지 않도록 처리
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: room.imageId != null
                      ? Image.network(
                          'http://127.0.0.1:5000/api/images/${room.imageId}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[300]),
                        )
                      : Container(color: Colors.grey[300]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            room.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildDdayStatus(room.startDate, room.endDate),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${room.country} / ${DateFormat('yyyy.MM.dd').format(room.startDate)} ~ ${DateFormat('yyyy.MM.dd').format(room.endDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
