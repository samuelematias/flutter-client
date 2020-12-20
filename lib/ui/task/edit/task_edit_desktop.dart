import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/ui/app/entity_dropdown.dart';
import 'package:invoiceninja_flutter/ui/app/form_card.dart';
import 'package:invoiceninja_flutter/ui/app/forms/custom_field.dart';
import 'package:invoiceninja_flutter/ui/app/forms/date_picker.dart';
import 'package:invoiceninja_flutter/ui/app/forms/decorated_form_field.dart';
import 'package:invoiceninja_flutter/ui/app/forms/duration_picker.dart';
import 'package:invoiceninja_flutter/ui/app/forms/dynamic_selector.dart';
import 'package:invoiceninja_flutter/ui/app/forms/project_picker.dart';
import 'package:invoiceninja_flutter/ui/app/forms/time_picker.dart';
import 'package:invoiceninja_flutter/ui/app/forms/user_picker.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_items_desktop.dart';
import 'package:invoiceninja_flutter/ui/task/edit/task_edit_details_vm.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/redux/client/client_selectors.dart';

class TaskEditDesktop extends StatefulWidget {
  const TaskEditDesktop({
    Key key,
    @required this.viewModel,
  }) : super(key: key);

  final TaskEditDetailsVM viewModel;

  @override
  _TaskEditDesktopState createState() => _TaskEditDesktopState();
}

class _TaskEditDesktopState extends State<TaskEditDesktop> {
  final _numberController = TextEditingController();
  final _rateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _custom1Controller = TextEditingController();
  final _custom2Controller = TextEditingController();
  final _custom3Controller = TextEditingController();
  final _custom4Controller = TextEditingController();

  final _debouncer = Debouncer();
  List<TextEditingController> _controllers = [];

  @override
  void didChangeDependencies() {
    _controllers = [
      _numberController,
      _rateController,
      _descriptionController,
      _custom1Controller,
      _custom2Controller,
      _custom3Controller,
      _custom4Controller,
    ];

    _controllers.forEach((controller) => controller.removeListener(_onChanged));

    final task = widget.viewModel.task;
    _numberController.text = task.number;
    _rateController.text = formatNumber(task.rate, context,
        formatNumberType: FormatNumberType.inputMoney);
    _descriptionController.text = task.description;
    _custom1Controller.text = task.customValue1;
    _custom2Controller.text = task.customValue2;
    _custom3Controller.text = task.customValue3;
    _custom4Controller.text = task.customValue4;

    _controllers.forEach((controller) => controller.addListener(_onChanged));

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _controllers.forEach((controller) {
      controller.removeListener(_onChanged);
      controller.dispose();
    });

    super.dispose();
  }

  void _onChanged() {
    _debouncer.run(() {
      final task = widget.viewModel.task.rebuild((b) => b
        ..number = _numberController.text.trim()
        ..rate = parseDouble(_rateController.text.trim())
        ..description = _descriptionController.text.trim()
        ..customValue1 = _custom1Controller.text.trim()
        ..customValue2 = _custom2Controller.text.trim()
        ..customValue3 = _custom3Controller.text.trim()
        ..customValue4 = _custom4Controller.text.trim());
      if (task != widget.viewModel.task) {
        widget.viewModel.onChanged(task);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final localization = AppLocalization.of(context);
    final task = viewModel.task;
    final state = viewModel.state;

    final taskTimes = task.taskTimes;
    if (!taskTimes.any((taskTime) => taskTime.isEmpty)) {
      taskTimes.add(TaskTime().rebuild((b) => b..startDate = null));
    }

    return ListView(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: FormCard(
                crossAxisAlignment: CrossAxisAlignment.start,
                padding: const EdgeInsets.only(
                    top: kMobileDialogPadding,
                    right: kMobileDialogPadding / 2,
                    bottom: kMobileDialogPadding,
                    left: kMobileDialogPadding),
                children: [
                  if (!task.isInvoiced) ...[
                    EntityDropdown(
                      key: Key('__client_${task.clientId}__'),
                      entityType: EntityType.client,
                      labelText: localization.client,
                      entityId: task.clientId,
                      entityList: memoizedDropdownClientList(
                          state.clientState.map,
                          state.clientState.list,
                          state.userState.map,
                          state.staticState),
                      onSelected: (client) {
                        viewModel.onChanged(task.rebuild((b) => b
                          ..clientId = client?.id
                          ..projectId = null));
                      },
                      onAddPressed: (completer) {
                        viewModel.onAddClientPressed(context, completer);
                      },
                    ),
                    ProjectPicker(
                      key: Key('__project_${task.clientId}__'),
                      projectId: task.projectId,
                      clientId: task.clientId,
                      onChanged: (selectedId) {
                        final project = state.projectState.get(selectedId);
                        viewModel.onChanged(task.rebuild((b) => b
                          ..projectId = project?.id
                          ..clientId = (project?.clientId ?? '').isNotEmpty
                              ? project.clientId
                              : task.clientId));
                      },
                      onAddPressed: (completer) {
                        viewModel.onAddProjectPressed(context, completer);
                      },
                    ),
                  ],
                  UserPicker(
                    userId: task.assignedUserId,
                    onChanged: (userId) => viewModel.onChanged(
                        task.rebuild((b) => b..assignedUserId = userId)),
                  ),
                  CustomField(
                    controller: _custom1Controller,
                    field: CustomFieldType.task1,
                    value: task.customValue1,
                  ),
                  CustomField(
                    controller: _custom3Controller,
                    field: CustomFieldType.task3,
                    value: task.customValue3,
                  ),
                ],
              ),
            ),
            Expanded(
              child: FormCard(
                crossAxisAlignment: CrossAxisAlignment.start,
                padding: const EdgeInsets.only(
                    top: kMobileDialogPadding,
                    right: kMobileDialogPadding / 2,
                    bottom: kMobileDialogPadding,
                    left: kMobileDialogPadding / 2),
                children: [
                  if (task.isOld)
                    DecoratedFormField(
                      controller: _numberController,
                      label: localization.taskNumber,
                      autocorrect: false,
                    ),
                  DynamicSelector(
                    key: ValueKey('__task_status_${task.statusId}__'),
                    allowClearing: false,
                    entityType: EntityType.taskStatus,
                    labelText: localization.status,
                    entityId: task.statusId,
                    entityIds: state.taskStatusState.list.toList(),
                    onChanged: (selectedId) {
                      final taskStatus = state.taskStatusState.map[selectedId];
                      viewModel.onChanged(task.rebuild((b) => b
                        ..statusId = taskStatus?.id
                        ..statusSortOrder = 9999));
                    },
                  ),
                  DecoratedFormField(
                    controller: _rateController,
                    label: localization.rate,
                    keyboardType: TextInputType.number,
                  ),
                  CustomField(
                    controller: _custom2Controller,
                    field: CustomFieldType.task2,
                    value: task.customValue2,
                  ),
                  CustomField(
                    controller: _custom4Controller,
                    field: CustomFieldType.task4,
                    value: task.customValue4,
                  ),
                ],
              ),
            ),
            Expanded(
              child: FormCard(
                crossAxisAlignment: CrossAxisAlignment.start,
                padding: const EdgeInsets.only(
                    top: kMobileDialogPadding,
                    right: kMobileDialogPadding,
                    bottom: kMobileDialogPadding,
                    left: kMobileDialogPadding / 2),
                children: [
                  DecoratedFormField(
                    maxLines: 6,
                    controller: _descriptionController,
                    keyboardType: TextInputType.multiline,
                    label: localization.description,
                  ),
                ],
              ),
            ),
          ],
        ),
        FormCard(
          padding: const EdgeInsets.symmetric(horizontal: kMobileDialogPadding),
          child: Table(
            columnWidths: {
              4: FixedColumnWidth(kMinInteractiveDimension),
            },
            children: [
              TableRow(
                children: [
                  TableHeader(localization.date),
                  TableHeader(localization.startTime),
                  TableHeader(localization.endTime),
                  TableHeader(localization.duration),
                  TableHeader(''),
                ],
              ),
              for (var index = 0; index < taskTimes.length; index++)
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.only(right: kTableColumnGap),
                    child: DatePicker(
                      selectedDate: taskTimes[index].startDate == null
                          ? null
                          : convertDateTimeToSqlDate(
                              taskTimes[index].startDate),
                      onSelected: (date) {
                        print('## date - onSelected: $date');
                        final taskTime = taskTimes[index].copyWithDate(date);
                        viewModel.onUpdatedTaskTime(taskTime, index);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: kTableColumnGap),
                    child: TimePicker(
                      selectedDate: taskTimes[index].startDate,
                      selectedDateTime: taskTimes[index].startDate,
                      //allowClearing: true,
                      onSelected: (timeOfDay) {
                        print('## start date - onSelected: $timeOfDay');
                        final taskTime = taskTimes[index].copyWithStartDateTime(timeOfDay);
                        viewModel.onUpdatedTaskTime(taskTime, index);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: kTableColumnGap),
                    child: TimePicker(
                      //key: ValueKey('$_startDate$_durationChanged'),
                      selectedDate: taskTimes[index].startDate,
                      selectedDateTime: taskTimes[index].endDate,
                      //allowClearing: true,
                      onSelected: (timeOfDay) {
                        print('## end date - onSelected: $timeOfDay');
                        final taskTime = taskTimes[index].copyWithEndDateTime(timeOfDay);
                        viewModel.onUpdatedTaskTime(taskTime, index);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: kTableColumnGap),
                    child: DurationPicker(
                      //key: ValueKey(_endDateChanged),
                      //allowClearing: true,
                      onSelected: (Duration duration) {
                        setState(() {
                          //_endDate = _startDate.add(duration);
                          //_durationChanged = DateTime.now();
                        });
                      },
                      selectedDuration: (taskTimes[index].startDate == null ||
                              taskTimes[index].endDate == null)
                          ? null
                          : taskTimes[index].duration,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear),
                    tooltip: localization.remove,
                    onPressed: taskTimes[index].isEmpty
                        ? null
                        : () {
                            //viewModel.onRemoveInvoiceItemPressed(index);
                            //_updateTable();
                          },
                  ),
                ]),
            ],
          ),
        )
      ],
    );
  }
}