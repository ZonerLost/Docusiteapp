import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/edit_profile/edit_profile_controller.dart';

// Change to GetView for direct access to the controller
class EditProfile extends GetView<EditProfileController> {
  const EditProfile({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(EditProfileController());

    return Scaffold(
      appBar: simpleAppBar(title: "Edit Profile"),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: kFillColor,
              border: Border.all(width: 1.0, color: kBorderColor),
            ),
            child: Row(
              children: [
                Obx(() {
                  ImageProvider<Object> imageProvider;
                  if (controller.imageFile.value != null) {
                    imageProvider = FileImage(controller.imageFile.value!);
                  } else if (controller.networkImageUrl.value.isNotEmpty) {
                    imageProvider = NetworkImage(controller.networkImageUrl.value);
                  } else {
                    // Fallback to a dummy/placeholder image
                    imageProvider = AssetImage(Assets.imagesCamera);
                  }

                  return CircleAvatar(
                    radius: 22,
                    backgroundImage: imageProvider,
                  );
                }),
                const SizedBox(width: 8),
                 Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MyText(
                        text: "Upload Profile Photo",
                        size: 15,
                        weight: FontWeight.w500,
                      ),
                      MyText(
                        paddingTop: 4,
                        text: "File size (100 mb max)",
                        size: 12,
                        weight: FontWeight.w500,
                        color: kQuaternaryColor,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: MyBorderButton(
                    borderColor: kSecondaryColor,
                    height: 30,
                    buttonText: '',
                    onTap: () {
                      // Show options to pick from camera or gallery
                      Get.bottomSheet(
                        Container(
                          color: Colors.white,
                          child: Wrap(
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Gallery'),
                                onTap: () {
                                  controller.pickImage(ImageSource.gallery);
                                  Get.back();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_camera),
                                title: const Text('Camera'),
                                onTap: () {
                                  controller.pickImage(ImageSource.camera);
                                  Get.back();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    radius: 8,
                    customChild: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         MyText(
                          paddingLeft: 6,
                          paddingRight: 4,
                          text: "Upload",
                          size: 12,
                          color: kSecondaryColor,
                          weight: FontWeight.w500,
                        ),
                        Image.asset(
                          Assets.imagesArrowDropdown,
                          height: 16,
                          color: kSecondaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
           MyText(
            text: 'PERSONAL INFORMATION',
            size: 12,
            weight: FontWeight.w500,
            color: kQuaternaryColor,
            paddingTop: 16,
            letterSpacing: 1.0,
            paddingBottom: 16,
          ),
          // Connect text fields to controllers
          MyTextField(
            controller: controller.nameController,
            labelText: "Full Name",
            hintText: 'Kevin Backer',
          ),
          MyTextField(
            controller: controller.emailController,
            labelText: "Email Address",
            hintText: 'Kevinbacker234@gmail.com',
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: AppSizes.DEFAULT,
        // Use Obx to show a loading indicator on the button
        child: Obx(
              () => MyButton(
            buttonText: controller.isLoading.value ? "" : "Update", // Hide text when loading
            onTap: controller.isLoading.value ? null : () => controller.updateProfile(),
            // Show a progress indicator when loading
            customChild: controller.isLoading.value
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.0,
              ),
            )
                : null,
          ),
        ),
      ),
    );
  }
}

// NOTE: I've assumed your MyTextField and MyButton widgets accept a `controller` and `child` property respectively.
// If not, you may need to adjust them like this:

/*
// In MyTextField
final TextEditingController? controller;
...
TextFormField(
  controller: controller,
  ...
)

// In MyButton
final Widget? child;
...
ElevatedButton(
  child: child ?? Text(buttonText),
  ...
)
*/