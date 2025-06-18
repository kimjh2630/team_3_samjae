// 검색/탭/리스트 화면만 담당
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:project/state/app_state.dart';
import 'package:project/widgets/language_dialog.dart';
import 'package:provider/provider.dart';
import '../component/medical_facility.dart';
import '../component/medical_facility_detailpage.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import 'widget/medical_facility_card.dart';

const String apiBase = 'http://10.0.2.2:8000';

class HospitalSearchResultPage extends StatefulWidget {
  const HospitalSearchResultPage({Key? key}) : super(key: key);

  @override
  _HospitalSearchResultPageState createState() => _HospitalSearchResultPageState();
}

class _HospitalSearchResultPageState extends State<HospitalSearchResultPage> with SingleTickerProviderStateMixin {
  List<MedicalFacility> facilities = [];
  bool isLoading = false;
  bool _isPaginating = false;
  int _currentPage = 1;
  final int _itemsPerPage = 25;
  int _totalCount = 0;
  Position? currentPosition;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  final List<String> subjectKeys = [
    'subject_nearby',
    'subject_internal',
    'subject_surgery',
    'subject_pediatrics',
    'subject_orthopedics',
    'subject_ent',
    'subject_dermatology',
    'subject_ophthalmology',
    'subject_neurology',
    'subject_neurosurgery',
    'subject_obgyn',
    'subject_urology',
    'subject_psychiatry',
    'subject_family',
    'subject_dentistry',
    'subject_oriental',
  ];
  final List<String> subjectNames = [
    '내 주변',
    '내과',
    '외과',
    '소아청소년과',
    '정형외과',
    '이비인후과',
    '피부과',
    '안과',
    '신경과',
    '신경외과',
    '산부인과',
    '비뇨기과',
    '정신건강의학과',
    '가정의학과',
    '치과',
    '한의원',
  ];
  late List<String> subjects;
  bool _mounted = true;
  bool _noMoreResultShown = false;
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = '';
    _scrollController.addListener(_scrollListener);
    _initializeSubjects();
    _tabController = TabController(length: subjects.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _resetNoMoreResultFlag();
      if (_tabController.index == 0) {
        _showNearbyHospitals();
      } else {
        _searchBySubject(subjects[_tabController.index]);
      }
    });

    // 화면 진입시 자동으로 내 주변 병원 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNearbyHospitals();
    });
  }

  void _initializeSubjects() {
    subjects = subjectKeys.map((key) => key.tr()).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeSubjects();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!isLoading && !_isPaginating && !_isLastPage && facilities.length < _totalCount) {
        _loadNextPage();
      } else if (!_isPaginating && (_isLastPage || facilities.length >= _totalCount) && !_noMoreResultShown) {
        // 마지막 페이지 도달 시 한 번만 안내
        _noMoreResultShown = true;
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('no_more_result'.tr())),
            );
          }
        });
      }
    }
  }

  void _performSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('input_keyword'.tr())),
      );
      return;
    }
    _resetNoMoreResultFlag();
    _startNewSearch();
  }

  Future<void> _startNewSearch() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
      facilities.clear();
      _currentPage = 1;
      _totalCount = 0;
    });
    try {
      await _fetchData(pageNo: _currentPage);
    } catch (e) {
      setState(() {
        facilities = [];
        _totalCount = 0;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchData({required int pageNo}) async {
    if (currentPosition == null) {
      final appState = context.read<AppState>();
      currentPosition = appState.position;
    }
    String url;
    String base = '$apiBase/api/medical/search?QN=${_searchController.text.trim()}&page_no=$pageNo&num_of_rows=$_itemsPerPage';
    if (currentPosition != null) {
      base += '&latitude=${currentPosition!.latitude}&longitude=${currentPosition!.longitude}';
    }
    url = base;
    try {
      final response = await http.get(Uri.parse(url));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List items = data['items'] ?? [];
        final int totalCount = data['total_count'] ?? 0;
        List<MedicalFacility> newFacilities = items.map((e) => MedicalFacility.fromJson(e)).toList();
        if (currentPosition != null) {
          for (var facility in newFacilities) {
            double? lat = parseCoordinate(facility.wgs84Lat);
            double? lon = parseCoordinate(facility.wgs84Lon);
            if (lat != null && lon != null) {
              facility.distance = calculateDistance(
                currentPosition!.latitude,
                currentPosition!.longitude,
                lat,
                lon,
              );
            } else {
              facility.distance = double.infinity;
            }
          }
        }
        if (currentPosition != null) {
          newFacilities = newFacilities.where((facility) {
            return facility.distance != null && facility.distance! <= 3000;
          }).toList();
          newFacilities.sort((a, b) {
            double ad = a.distance ?? double.infinity;
            double bd = b.distance ?? double.infinity;
            return ad.compareTo(bd);
          });
        }
        if (mounted) {
          setState(() {
            if (pageNo == 1) {
              facilities = newFacilities;
            } else {
              facilities = [...facilities, ...newFacilities];
            }
            _totalCount = totalCount;
            _isLastPage = newFacilities.length < _itemsPerPage;
          });
        }
      } else {
        if (mounted) {
          // 실패해도 기존 목록은 유지
          setState(() {
            // facilities = [];
            _totalCount = 0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // 실패해도 기존 목록은 유지
        setState(() {
          // facilities = [];
          _totalCount = 0;
        });
      }
    }
  }

  void _searchBySubject(String subject) async {
    _resetNoMoreResultFlag();
    setState(() {
      isLoading = true;
      facilities.clear();
      _currentPage = 1;
      _totalCount = 0;
    });
    // subjectNames에서 한글명으로 QN 파라미터 전송
    int idx = subjects.indexOf(subject);
    String qn = idx >= 0 ? subjectNames[idx] : subject;
    await _fetchDataBySubject(subject: qn, pageNo: 1);
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchDataBySubject({required String subject, required int pageNo}) async {
    if (currentPosition == null) {
      final appState = context.read<AppState>();
      currentPosition = appState.position;
    }
    String url = '$apiBase/api/medical/search?QN=$subject&page_no=$pageNo&num_of_rows=$_itemsPerPage';
    if (currentPosition != null) {
      url += '&latitude=${currentPosition!.latitude}&longitude=${currentPosition!.longitude}';
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List items = data['items'] ?? [];
        final int totalCount = data['total_count'] ?? 0;
        List<MedicalFacility> newFacilities = items.map((e) => MedicalFacility.fromJson(e)).toList();
        if (currentPosition != null) {
          for (var facility in newFacilities) {
            double? lat = parseCoordinate(facility.wgs84Lat);
            double? lon = parseCoordinate(facility.wgs84Lon);
            if (lat != null && lon != null) {
              facility.distance = calculateDistance(
                currentPosition!.latitude,
                currentPosition!.longitude,
                lat,
                lon,
              );
            } else {
              facility.distance = double.infinity;
            }
          }
        }
        int idx = subjectNames.indexOf(subject);
        if (idx > 0) {
          final selectedSubject = subjectNames[idx].replaceAll(' ', '').toLowerCase();
          if (selectedSubject == '한의원') {
            newFacilities = newFacilities.where((facility) {
              final dgidList = (facility.dgidIdName ?? '')
                  .split(',')
                  .map((s) => s.trim())
                  .toList();
              return dgidList.any((dgid) => dgid.contains('침구과') || dgid.contains('한방'));
            }).toList();
          } else if (selectedSubject == '비뇨기과') {
            newFacilities = newFacilities.where((facility) {
              final dgidList = (facility.dgidIdName ?? '')
                  .split(',')
                  .map((s) => s.trim())
                  .toList();
              return dgidList.any((dgid) => dgid.contains('비뇨'));
            }).toList();
          } else {
            newFacilities = newFacilities.where((facility) {
              final dgidList = (facility.dgidIdName ?? '')
                  .split(',')
                  .map((s) => s.trim().replaceAll(' ', '').toLowerCase())
                  .toList();
              return dgidList.any((dgid) => dgid.contains(selectedSubject));
            }).toList();
          }
        }
        if (currentPosition != null) {
          newFacilities = newFacilities.where((facility) {
            return facility.distance != null && facility.distance! <= 3000;
          }).toList();
          newFacilities.sort((a, b) {
            double ad = a.distance ?? double.infinity;
            double bd = b.distance ?? double.infinity;
            return ad.compareTo(bd);
          });
        }
        setState(() {
          if (pageNo == 1) {
            facilities = newFacilities;
          } else {
            facilities = [...facilities, ...newFacilities];
          }
          _totalCount = totalCount;
          _isLastPage = newFacilities.length < _itemsPerPage;
        });
      } else {
        setState(() {
          // facilities = [];
          _totalCount = 0;
        });
      }
    } catch (e) {
      setState(() {
        // facilities = [];
        _totalCount = 0;
      });
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  double? parseCoordinate(String? coord) {
    if (coord == null || coord.isEmpty) return null;
    try {
      return double.parse(coord);
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadNextPage() async {
    if (_isPaginating || isLoading) return;
    setState(() {
      _isPaginating = true;
      _currentPage += 1;
    });
    try {
      if (_tabController.index == 0) {
        // 내 주변 탭: 추가 페이지 없음 (필요시 서버 API에 맞게 구현)
        // await _showNearbyHospitals();
      } else if (_searchController.text.trim().isNotEmpty) {
        // 검색어가 있을 때
        await _fetchData(pageNo: _currentPage);
      } else {
        // 진료과목 탭
        await _fetchDataBySubject(subject: subjects[_tabController.index], pageNo: _currentPage);
      }
    } catch (e) {
      // 에러 처리
    } finally {
      setState(() {
        _isPaginating = false;
      });
    }
  }


  void _showLanguageDialog() {
    showDialog(context: context, builder: (context) => const LanguageDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'hospital_search'.tr(),
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: _showLanguageDialog,
            tooltip: 'language_selection'.tr(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'search_hint'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _performSearch,
                  color: Colors.black87,
                ),
              ],
            ),
          ),
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: subjects.length,
              itemBuilder: (context, idx) {
                final selected = _tabController.index == idx;
                return GestureDetector(
                  onTap: () {
                    _tabController.animateTo(idx);
                    if (idx == 0) {
                      _showNearbyHospitals();
                    } else {
                      _searchBySubject(subjects[idx]);
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          selected ? Color(0xFF146DA3) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color:
                            selected ? Color(0xFF146DA3) : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (idx == 0) ...[
                            Icon(
                              Icons.my_location,
                              size: 18,
                              color: selected ? Colors.white : Colors.black54,
                            ),
                            SizedBox(width: 4),
                          ],
                          Text(
                            subjects[idx],
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child:
                isLoading && facilities.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : facilities.isEmpty
                    ? Center(
                      child: Text(
                        'no_result'.tr(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: facilities.length + (_isPaginating ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == facilities.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final f = facilities[index];
                        String? distanceText;
                        if (f.distance != null &&
                            f.distance != double.infinity) {
                          distanceText = formatDistance(f.distance!);
                        }
                        return MedicalFacilityCard(
                          facility: f,
                          distanceText: distanceText,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => MedicalFacilityDetailPage(
                                      facility: f,
                                      fromMainHospitalSearch: true,
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  String formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.round()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  void _showNearbyHospitals() async {
    if (!mounted) return;
    setState(() { isLoading = true; });
    try {
      // AppState에서 저장된 위치 정보 가져오기
      final appState = context.read<AppState>();
      Position? position = appState.position;

      if (position == null) {
        throw Exception("locationNotFound".tr());
      }

      // 이미 캐시된 병원 목록이 있는지 확인
      List<MedicalFacility>? cachedHospitals = appState.hospitals;
      if (cachedHospitals != null && cachedHospitals.isNotEmpty) {
        // 1km 이내 병원 우선, 그 외 병원 추가로 보여주기
        List<MedicalFacility> within1km = cachedHospitals.where((f) => f.distance != null && f.distance! <= 1000).toList();
        List<MedicalFacility> over1km = cachedHospitals.where((f) => f.distance == null || f.distance! > 1000).toList();
        setState(() {
          facilities = [...within1km, ...over1km];
          isLoading = false;
        });
        return;
      }

      // 캐시된 데이터가 없는 경우에만 API 호출
      final response = await http.get(
          Uri.parse('$apiBase/api/medical/nearby?latitude=${position.latitude}&longitude=${position.longitude}&radius=10000&type=hospital')
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List items = data['items'] ?? [];
        List<MedicalFacility> hospitals = items.map((item) => MedicalFacility.fromJson(item)).toList();

        // 거리 계산 및 정렬
        for (var facility in hospitals) {
          double? lat = parseCoordinate(facility.wgs84Lat);
          double? lon = parseCoordinate(facility.wgs84Lon);
          if (lat != null && lon != null) {
            facility.distance = calculateDistance(
              position.latitude,
              position.longitude,
              lat,
              lon,
            );
          } else {
            facility.distance = double.infinity;
          }
        }

        hospitals.sort((a, b) {
          double ad = a.distance ?? double.infinity;
          double bd = b.distance ?? double.infinity;
          return ad.compareTo(bd);
        });

        // 1km 이내 병원 우선, 그 외 병원 추가로 보여주기
        List<MedicalFacility> within1km = hospitals.where((f) => f.distance != null && f.distance! <= 1000).toList();
        List<MedicalFacility> over1km = hospitals.where((f) => f.distance == null || f.distance! > 1000).toList();

        // 상태 업데이트 및 캐시 저장
        if (mounted) {
          setState(() {
            facilities = [...within1km, ...over1km];
            isLoading = false;
          });
          appState.hospitals = hospitals;  // 캐시에 저장
        }
      } else {
        throw Exception("serverError".tr());
      }
    } catch (e) {
      if (mounted) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()))
        );
      }
    }
  }

  void _resetNoMoreResultFlag() {
    _noMoreResultShown = false;
    _isLastPage = false;
  }
}
