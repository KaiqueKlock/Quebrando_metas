import 'package:flutter/material.dart';
import 'package:quebrando_metas/core/widgets/empty_state.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyState(
        title: 'Nenhuma meta cadastrada',
        message: 'Crie sua primeira meta para iniciar.',
      ),
    );
  }
}
