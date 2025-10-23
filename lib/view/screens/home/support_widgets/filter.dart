import 'package:flutter/cupertino.dart';
import 'package:get/Get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../controllers/home/home_controller.dart';
import '../../../widget/custom_drop_down_widget.dart';
import '../../../widget/custom_tag_field_widget.dart';
import '../../../widget/my_button_widget.dart';
import '../../../widget/my_text_widget.dart';

class Filter extends StatelessWidget {
  final TextEditingController clientController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController pdfController = TextEditingController();
  final RxString selectedProgress = ''.obs;

  @override
  Widget build(BuildContext context) {
    final HomeController viewModel = Get.find();

    // Initialize controllers with current filter values
    clientController.text = viewModel.filterClient.value;
    locationController.text = viewModel.filterLocation.value;
    selectedProgress.value = viewModel.filterProgress.value;

    return Container(
      height: Get.height * 0.8,
      margin: const EdgeInsets.only(top: 55),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyText(
            text: 'Select Filters',
            size: 18,
            weight: FontWeight.w500,
            paddingBottom: 8,
          ),
          MyText(
            text: 'Please select the filters as per your preferences.',
            color: kQuaternaryColor,
            weight: FontWeight.w500,
            size: 13,
          ),
          Container(
            height: 1,
            color: kBorderColor,
            margin: const EdgeInsets.symmetric(vertical: 12),
          ),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: AppSizes.ZERO,
              physics: const BouncingScrollPhysics(),
              children: [
                CustomTagField(
                  labelText: 'Search by Client',
                  controller: clientController,
                  onChanged: (value) {},
                ),
                CustomTagField(
                  labelText: 'Search by Location',
                  controller: locationController,
                  onChanged: (value) {},
                ),
                Obx(() => CustomDropDown(
                  labelText: 'Search by progress',
                  hintText: 'Select progress',
                  items: const ['', '0%', '25%', '50%', '75%', '100%'],
                  selectedValue: selectedProgress.value,
                  onChanged: (value) {
                    selectedProgress.value = value ?? '';
                  },
                )),
                CustomTagField(
                  labelText: 'Search by PDF',
                  controller: pdfController,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: MyBorderButton(
                  buttonText: 'Reset',
                  onTap: () {
                    clientController.clear();
                    locationController.clear();
                    pdfController.clear();
                    selectedProgress.value = '';
                    viewModel.clearFilters();
                    Get.back();
                  },
                  textColor: kQuaternaryColor,
                  bgColor: kFillColor,
                  borderColor: kBorderColor,
                ),
              ),
              Expanded(
                child: MyButton(
                  buttonText: 'Apply Filters',
                  onTap: () {
                    viewModel.applyFilters(
                      client: clientController.text,
                      location: locationController.text,
                      progress: selectedProgress.value,
                      pdf: pdfController.text,
                    );
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

