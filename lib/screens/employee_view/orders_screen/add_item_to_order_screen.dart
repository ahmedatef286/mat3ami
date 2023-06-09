import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mat3ami/business_logic/models/menu_item.dart' as m;
import 'package:mat3ami/business_logic/services/menu_item_services.dart';
import 'package:mat3ami/business_logic/services/order_services.dart';
import 'package:mat3ami/business_logic/view_models/menu_view_model.dart';

import 'package:mat3ami/screens/common_components/common_components.dart';
import 'package:mat3ami/screens/table_keeping_available/table_keeping_occupied.dart';
import 'package:mat3ami/style/style.dart';
import 'package:provider/provider.dart';

class AddItemToOrderScreen extends StatefulWidget {
  AddItemToOrderScreen({super.key, required this.tableNum});
  int tableNum;
  @override
  State<AddItemToOrderScreen> createState() => _AddItemToOrderScreenState();
}

class _AddItemToOrderScreenState extends State<AddItemToOrderScreen>
    with SingleTickerProviderStateMixin {
  Map<String, List<dynamic>> orderdItemNamesCountsPricesImagesCategories = {};
  late final TabController _tabController;
  late List<m.MenuItem> menuItemList;
  TextEditingController commentsConttroller = TextEditingController();
  var timer;
  final List<Tab> myTabs = [
    Tab(text: 'Koshary'),
    Tab(text: 'Additions'),
    Tab(text: 'Dessert'),
    Tab(text: 'Drinks')
  ];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: myTabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    initalizeMenu();
    commentsConttroller.text = '';

    timer = Timer.periodic(
        Duration(seconds: 5),
        (Timer t) => Provider.of<MenuViewModel>(context, listen: false)
            .updateMenuList());
  }

  @override
  void dispose() {
    _tabController.dispose();
    timer.cancel();
    super.dispose();
  }

  Future<void> initalizeMenu() async {
    menuItemList = await MenuItemServices.fetchAllMenuItemsFromDatabase();
    for (final element in menuItemList) {
      orderdItemNamesCountsPricesImagesCategories['${element.name}'] = [
        0,
        element.price,
        element.imageBytes,
        element.category
      ];
    }

    setState(() {});
  }

  void _handleTabSelection() {
    setState(() {
      // Retrieve the selected tab value
      String? selectedTab = myTabs[_tabController.index].text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
            indicatorWeight: 3,
            indicatorColor: CustomStyle.colorPalette.orange,
            controller: _tabController,
            labelColor: CustomStyle.colorPalette.orange,
            unselectedLabelColor: CustomStyle.colorPalette.textColor,
            tabs: myTabs),
        centerTitle: true,
        toolbarHeight: MediaQuery.of(context).size.height * 0.1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Menu",
          style: TextStyle(
              color: CustomStyle.colorPalette.textColor,
              fontFamily: CustomStyle.fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: CustomStyle.fontSizes.titleFont),
        ),
        backgroundColor: CustomStyle.colorPalette.darkBackground,
      ),
      backgroundColor: CustomStyle.colorPalette.lightBackgorund,
      body: Column(
        children: [
          Flexible(
            flex: 13,
            child: TabBarView(
              controller: _tabController,
              children: myTabs.map((e) {
                return GridView.count(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.1),
                  mainAxisSpacing: MediaQuery.of(context).size.height * 0.1,
                  crossAxisSpacing: 20,
                  childAspectRatio:
                      ((MediaQuery.of(context).size.width * 0.45) /
                          (MediaQuery.of(context).size.height * 0.29)),
                  crossAxisCount: 2,
                  children: orderdItemNamesCountsPricesImagesCategories.entries
                      .where((element) => element.value[3] == e.text)
                      .map((key) {
                    return menuItemWidget(
                        key.key, key.value[0], key.value[1], key.value[2]);
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          Flexible(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircleAvatar(
                      radius: MediaQuery.of(context).size.height * 0.047,
                      backgroundColor: CustomStyle.colorPalette.orange,
                      child: TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) {
                                return Material(
                                  child: Container(
                                    color: CustomStyle
                                        .colorPalette.lightBackgorund,
                                    child: Center(
                                        child: SizedBox(
                                      child: customTextField(
                                        textEditingController:
                                            commentsConttroller,
                                        hintText: 'Add Comments',
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.9,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.1,
                                      ),
                                    )),
                                  ),
                                );
                              },
                            );
                          },
                          child: Text(
                            "C",
                            style: TextStyle(
                                color: CustomStyle.colorPalette.textColor,
                                fontFamily: CustomStyle.fontFamily,
                                fontWeight: FontWeight.bold,
                                fontSize: CustomStyle.fontSizes.titleFont),
                          ))),
                  customButton(
                      context: context,
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return Container(
                              color: CustomStyle.colorPalette.lightBackgorund,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: CustomStyle.colorPalette.orange,
                                ),
                              ),
                            );
                          },
                        );
                        Map<String, int> orderedItems = {};
                        orderdItemNamesCountsPricesImagesCategories.entries
                            .forEach((element) {
                          if (element.value[0] > 0) {
                            orderedItems[element.key] = element.value[0];
                          }
                        });
                        if (orderedItems.isEmpty) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('No items selected')));
                          Navigator.of(context, rootNavigator: true).pop();
                          return;
                        }

                        await OrderServices.addOrderToDatabase(widget.tableNum,
                            orderedItems, commentsConttroller.text);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Order Placed succsefully')));
                        Navigator.of(context, rootNavigator: true).pop();
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => OccupiedTableKeeping(
                                    tableNumber: widget.tableNum,
                                  )),
                        );
                      },
                      childText: 'Add To Order')
                ],
              ))
        ],
      ),
    );
  }

  Widget menuItemWidget(
      String itemName, int itemCount, double itemPrice, String imageBytes) {
    return customContainer(
        child: Stack(
      alignment: AlignmentDirectional.center,
      clipBehavior: Clip.none,
      children: [
        customContainer(
            width: MediaQuery.of(context).size.width * 0.45,
            height: MediaQuery.of(context).size.height * 0.27,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "$itemName",
                  style: TextStyle(
                      fontFamily: CustomStyle.fontFamily,
                      fontSize: CustomStyle.fontSizes.itemOrderFont,
                      color: CustomStyle.colorPalette.textColor),
                ),
                Text(''),
                Text(
                  '$itemPrice',
                  style: TextStyle(
                      fontFamily: CustomStyle.fontFamily,
                      fontSize: CustomStyle.fontSizes.orderDetailsFont,
                      color: CustomStyle.colorPalette.textColor),
                ),
                Text(''),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CircleAvatar(
                      backgroundColor: CustomStyle.colorPalette.lightBackgorund,
                      child: IconButton(
                        onPressed: (() {
                          if (itemCount != 0) {
                            setState(() {
                              orderdItemNamesCountsPricesImagesCategories[
                                  '$itemName']![0] -= 1;
                            });
                          }
                        }),
                        icon: Icon(Icons.remove),
                        color: CustomStyle.colorPalette.textColor,
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width * 0.1,
                      height: MediaQuery.of(context).size.height * 0.04,
                      color: CustomStyle.colorPalette.lightBackgorund,
                      child: Text(
                        '$itemCount',
                        style: TextStyle(
                            fontFamily: CustomStyle.fontFamily,
                            fontSize: CustomStyle.fontSizes.itemOrderFont,
                            color: CustomStyle.colorPalette.textColor),
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: CustomStyle.colorPalette.lightBackgorund,
                      child: IconButton(
                        onPressed: (() {
                          setState(() {
                            orderdItemNamesCountsPricesImagesCategories[
                                '$itemName']![0] += 1;
                          });
                        }),
                        icon: Icon(Icons.add),
                        color: CustomStyle.colorPalette.textColor,
                      ),
                    ),
                  ],
                )
              ],
            )),
        Positioned(
            top: MediaQuery.of(context).size.height * -0.3 * 0.25,
            child: CircleAvatar(
              radius: MediaQuery.of(context).size.height * 0.092,
              backgroundColor: Colors.transparent,
              backgroundImage: m.MenuItem.decodeImage(imageBytes).image,
            ))
      ],
    ));
  }
}
