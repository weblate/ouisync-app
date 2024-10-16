import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

// The simplest cubit. We can't use `Cubit` directly because that is abstract.
class Value<State> extends Cubit<State> {
  Value(State initial) : super(initial);

  Widget builder(Widget Function(State) func) {
    return BlocBuilder<Value<State>, State>(
      bloc: this,
      builder: (BuildContext ctx, State state) {
        return func(state);
      },
    );
  }

  void changed() {
    emit(state);
  }

  void update(void Function(State) f) {
    f(state);
    changed();
  }
}
