import 'package:get/get.dart';
import 'package:docu_site/utils/Utils.dart';

import '../../models/project/project.dart';
import '../../models/project/project_file.dart';
import '../../services/project_services/firestore_project_services.dart'; // Assuming this exists for snackbars

// Controller to manage state and logic for the ProjectDetails screen.
class ProjectDetailsController extends GetxController {
  final ProjectService _projectService = Get.find<ProjectService>();

  // Observable for the current project data
  final Rx<Project?> project = Rx<Project?>(null);

  // Holds the ID of the project being viewed
  final String projectId;

  // Constructor requires the project ID to start fetching data
  ProjectDetailsController({required this.projectId});

  @override
  void onInit() {
    super.onInit();
    // Start streaming the specific project data
    _streamProjectDetails();
  }

  void _streamProjectDetails() {
    // Start listening to the single document stream from the service
    _projectService.streamProject(projectId).listen((projectData) {
      project.value = projectData;
      if (projectData == null && project.value == null) {
        Utils.snackBar('Error', 'Project not found or you do not have access.');
      }
    }).onError((error) {
      Utils.snackBar('Error', 'Failed to fetch project details: ${error.toString()}');
    });
  }

  Map<String, List<ProjectFile>> get groupedFiles {
    if (project.value == null) return {};

    final Map<String, List<ProjectFile>> map = {};
    for (var file in project.value!.files) {
      // Ensure file category exists before using it as a key
      if (file.category.isNotEmpty) {
        if (!map.containsKey(file.category)) {
          map[file.category] = [];
        }
        map[file.category]!.add(file);
      }
    }
    return map;
  }

  // Filters collaborators to get the count
  int get memberCount => project.value?.collaborators.length ?? 0;

  // Get owner name for display
  String get projectOwnerName {
    final ownerId = project.value?.ownerId;
    if (ownerId == null) return 'Unknown Owner';

    final owner = project.value?.collaborators.firstWhereOrNull(
          (c) => c.uid == ownerId,
    );
    return owner?.name ?? 'Unknown Owner';
  }

  // --- Placeholder Actions (for UI buttons) ---

  void deleteProject() {
    Utils.snackBar('Action', 'Delete project functionality TBD for ID: $projectId.');
  }

  void editProject() {
    Utils.snackBar('Action', 'Edit project functionality TBD for ID: $projectId.');
  }

  void addMember(String name, String email, String role) {
    // This logic would involve looking up the user by email/name and adding them
    // to the project's 'collaborators' array in Firestore.
    Utils.snackBar('Action', 'Inviting member $name with role $role TBD.');
  }

  void addNewPdf(String category, String fileUrl, String fileName) {
    // This logic would involve uploading the file to Firebase Storage
    // and updating the project's 'files' array in Firestore.
    Utils.snackBar('Action', 'Upload of "$fileName" to category $category TBD.');
  }
}
