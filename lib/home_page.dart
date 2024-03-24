import 'dart:convert';

import 'package:final_640710974/helpers/my_list_tile.dart';
import 'package:flutter/material.dart';
import 'todo_item.dart';
import '../helpers/api_caller.dart';
import '../helpers/dialog_utils.dart';
//import '../helpers/my_list_tile.dart';
import '../helpers/my_text_field.dart';

int count = 0;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<TodoItem> _todoItems = [];

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    textController2 = TextEditingController();
    _loadTodoItems();
  }

  @override
  void dispose() {
    textController.dispose();
    textController2.dispose();
    super.dispose();
  }

  var textController = TextEditingController();
  var textController2 = TextEditingController();
  Future<void> _loadTodoItems() async {
    try {
      final data = await ApiCaller().get("web_types");
      // ข้อมูลที่ได้จาก API นี้จะเป็น JSON array ดังนั้นต้องใช้ List รับค่าจาก jsonDecode()
      List list = jsonDecode(data);

      setState(() {
        _todoItems = list.map((e) => TodoItem.fromJson(e)).toList();
      });
    } on Exception catch (e) {
      showOkDialog(context: context, title: "Error", message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    //var textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Text(
              'Webby Fondue',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            Text(
              'ระบบรายงานเว็บเลวๆ',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('* ต้องกรอกข้อมูล', style: TextStyle(fontSize: 20)),
            MyTextField(
              controller: textController,
              hintText: "URL*",
            ),
            const SizedBox(height: 12.0),
            MyTextField(
              controller: textController2,
              hintText: "รายละเอียด",
            ),
            const SizedBox(height: 12.0),
            Expanded(
              child: ListView.builder(
                itemCount: _todoItems.length,
                itemBuilder: (context, index) {
                  final item = _todoItems[index];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        for (var i = 0; i < _todoItems.length; i++) {
                          _todoItems[i].selected = false;
                        }

                        _todoItems[index].selected = true;
                      });
                    },
                    child: MyListTile(
                      title: item.title,
                      subtitle: item.subtitle,
                      imageUrl: item.image,
                      selected: item.selected,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _handleApiPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: Text(
                'ส่งข้อมูล',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20, // Increase the font size here
                ),
              ),
            ),
            const SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApiPost() async {
    if (textController.text.isEmpty ||
        !_todoItems.any((item) => item.selected)) {
      showOkDialog(
          context: context,
          title: "Error",
          message: 'กรุณากรอก URL และเลือกประเภทเว็บ');
      return;
    }

    String selectedTypeId;
    try {
      // Get the selected item's id
      selectedTypeId = _todoItems.firstWhere((item) => item.selected).id;
    } catch (e) {
      showOkDialog(
          context: context, title: "Error", message: 'ไม่พบประเภทเว็บที่เลือก');
      return;
    }

    try {
      final data = await ApiCaller().post(
        "report_web",
        params: {
          "id": count,
          "url": textController.text,
          "description": textController2.text,
          "type": selectedTypeId,
        },
      );
      textController.clear();
     textController2.clear();
      Map map = jsonDecode(data);
      var summary = map['summary'];
      String text = 'ขอบคุณสำหรับการแจ้งข้อมูล รหัสข้อมูลของคุณคือ ' +
          map['insertItem']['id'].toString();
      summary.forEach((summaryItem) {
        text +=
            '\n${summaryItem['title']} : ${summaryItem['count'].toString()}';
      });

      showOkDialog(context: context, title: "Success", message: text);
    } catch (genericError) {
      
      showOkDialog(
          context: context, title: "Error", message: genericError.toString());
    }
  }
}
