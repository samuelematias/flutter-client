import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/ui/invoice/invoice_pdf.dart';
import 'package:invoiceninja_flutter/ui/invoice/invoice_pdf_vm.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';

class QuotePdfScreen extends StatelessWidget {
  const QuotePdfScreen({Key key}) : super(key: key);

  static const String route = '/quote/pdf';

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, QuotePdfVM>(
      converter: (Store<AppState> store) {
        return QuotePdfVM.fromStore(store);
      },
      builder: (context, vm) {
        return InvoicePdfView(
          key: ValueKey('__quote_pdf_${vm.invoice.id}__'),
          viewModel: vm,
        );
      },
    );
  }
}

class QuotePdfVM extends EntityPdfVM {
  QuotePdfVM({
    AppState state,
    InvoiceEntity invoice,
  }) : super(
          state: state,
          invoice: invoice,
        );

  factory QuotePdfVM.fromStore(Store<AppState> store) {
    final state = store.state;
    final invoiceId = state.uiState.quoteUIState.selectedId;
    final invoice = state.quoteState.get(invoiceId);

    return QuotePdfVM(
      state: state,
      invoice: invoice,
    );
  }
}
