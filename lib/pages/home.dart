import 'package:driver/pages/free_route_trip.dart';
import 'package:driver/pages/requested_trip.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Container(
        height: double.maxFinite,
        width: double.maxFinite,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Escolha o cenário para simulação',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(
              height: 32,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => RequestedTripPage(title: 'Corrida Solicitada')));
              },
              child: Container(
                width: 200,
                child: Center(child: Text('Corrida Solicitada')),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => FreeRoutePage(title: 'Corrida Rota Livre')));
              },
              child: Container(
                width: 200,
                child: Center(child: Text('Rota Livre')),
              ),
            )
          ],
        ),
      ),
    );
  }
}
