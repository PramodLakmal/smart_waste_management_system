import 'package:flutter/material.dart';

class BinSummaryScreen extends StatelessWidget {
  final List<String> collectedBins;

  BinSummaryScreen({required this.collectedBins, required List collectedBinIds});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collected Bins Summary'),
      ),
      body: collectedBins.isEmpty
          ? Center(child: Text('No bins were collected.'))
          : ListView.builder(
              itemCount: collectedBins.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Collected Bin ID: ${collectedBins[index]}'),
                  leading: Icon(Icons.check_circle, color: Colors.green),
                );
              },
            ),
    );
  }
}
