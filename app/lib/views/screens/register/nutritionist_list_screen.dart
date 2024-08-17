import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:tamotsu/models/nutritionist.dart';
import 'package:tamotsu/routes/app_router.dart';
import 'package:tamotsu/viewmodels/nutritionist_view_model.dart';

@RoutePage()
class NutritionistListScreen extends StatefulWidget {
  NutritionistListScreen({Key? key}) : super(key: key);

  @override
  _NutritionistListScreenState createState() => _NutritionistListScreenState();
}

class _NutritionistListScreenState extends State<NutritionistListScreen> {
  int currentPage = 1;
  bool hasReachedEnd = false;
  TextEditingController searchController = TextEditingController();
  ScrollController scrollController = ScrollController();
  String _query = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadNutritionists();
    });
    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
      loadMoreNutritionists();
    }
  }

  void loadNutritionists() {
    final viewModel = Provider.of<NutritionistViewModel>(context, listen: false);
    viewModel.fetchNutritionistList(search: (_query == "") ? null : _query, page: currentPage);
  }

  void loadMoreNutritionists() {
    if (!hasReachedEnd) {
      setState(() {
        currentPage++;
      });
      loadNutritionists();
    }
  }

  void searchNutritionists() {
    setState(() {
      currentPage = 1;
      hasReachedEnd = false;
    });
    final viewModel = Provider.of<NutritionistViewModel>(context, listen: false);
    viewModel.clearNutritionistList();
    viewModel.fetchNutritionistList(search: (_query == "") ? null : _query, page: currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('管理栄養士一覧')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: '検索',
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                setState(() {
                  _query = query;
                });
                searchNutritionists(); // クエリを引数として渡す
              },
            ),
          ),
          Expanded(
            child: Consumer<NutritionistViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading && currentPage == 1) {
                  return Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: viewModel.nutritionistList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == viewModel.nutritionistList.length) {
                      if (viewModel.isLoading) {
                        return Center(child: CircularProgressIndicator());
                      } else if (hasReachedEnd) {
                        return Center(child: Text('全ての結果を表示しました'));
                      } else {
                        return SizedBox.shrink();
                      }
                    }

                    final nutritionist = Nutritionist.fromJson(viewModel.nutritionistList[index]);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(nutritionist.imageUrl),
                      ),
                      title: Text(nutritionist.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nutritionist.introduction.length > 50
                              ? '${nutritionist.introduction.substring(0, 50)}...'
                              : nutritionist.introduction),
                          Text('得意分野: ${nutritionist.specialties.join(", ")}'),
                          Text('登録者数: ${nutritionist.registeredUsers}人'),
                        ],
                      ),
                      onTap: () {
                        context.pushRoute(NutritionistDetailRoute(nutritionist: nutritionist));
                      },
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
}