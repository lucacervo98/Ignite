import 'package:geolocator/geolocator.dart';
import 'package:ignite/dbcontrollers/firebasedbcontrollers/hydrants_firebasecontroller.dart';

import '../../dbcontrollers/firebasedbcontrollers/requests_firebasecontroller.dart';
import '../../factories/servicesfactories/firebaseservicesfactory.dart';
import '../../models/hydrant.dart';
import '../../models/request.dart';
import '../../models/user.dart';
import '../requests_services.dart';

class FirebaseRequestsServices implements RequestsServices {
  FirebaseRequestController _requestsController =
      new FirebaseRequestController();
  FirebaseHydrantsController _hydrantsController =
      new FirebaseHydrantsController();
  @override
  Future<Request> addRequest(
      Hydrant hydrant, bool isFireman, String userMail) async {
    Hydrant addedHydrant = await _hydrantsController.insert(hydrant);
    User requestedBy = await FirebaseServicesFactory()
        .getUsersServices()
        .getUserByMail(userMail);
    Request newRequest = new Request(
        isFireman, !isFireman, addedHydrant.getId(), requestedBy.getId());
    if (isFireman) {
      newRequest.setApprovedByUserId(requestedBy.getId());
    }
    return await _requestsController.insert(newRequest);
  }

  @override
  Future<void> approveRequest(
      Hydrant hydrant, Request request, String userMail) async {
    await _hydrantsController.update(hydrant);
    User approvedBy = await FirebaseServicesFactory()
        .getUsersServices()
        .getUserByMail(userMail);
    request.setApproved(true);
    request.setOpen(false);
    request.setApprovedByUserId(approvedBy.getId());
    await _requestsController.update(request);
  }

  @override
  Future<void> denyRequest(Request request) async {
    await _hydrantsController.delete(request.getHydrantId());
    await _requestsController.delete(request.getId());
  }

  @override
  Future<List<Request>> getApprovedRequests() async {
    List<Request> allRequests = await this.getRequests();
    List<Request> approvedRequests = new List<Request>();
    for (Request request in allRequests) {
      if (!request.isOpen() && request.getApproved()) {
        approvedRequests.add(request);
      }
    }
    return approvedRequests;
  }

  @override
  Future<List<Request>> getPendingRequestsByDistance(
      double latitude, double longitude) async {
    List<Request> allRequests =
        await this.getRequestsByDistance(latitude, longitude);
    List<Request> pendingRequests = new List<Request>();
    for (Request request in allRequests) {
      if (request.isOpen() && !request.getApproved())
        pendingRequests.add(request);
    }
    return pendingRequests;
  }

  @override
  Future<List<Request>> getRequests() async {
    return await _requestsController.getAll();
  }

  @override
  Future<List<Request>> getRequestsByDistance(
      double latitude, double longitude) async {
    List<Request> allRequests = await _requestsController.getAll();
    List<Request> filteredRequests = new List<Request>();

    for (Request request in allRequests) {
      Hydrant hydrant = await FirebaseServicesFactory()
          .getHydrantsServices()
          .getHydrantById(request.getHydrantId());
      double distance = await Geolocator().distanceBetween(
          latitude, longitude, hydrant.getLat(), hydrant.getLong());
      if (distance < 20000) filteredRequests.add(request);
    }
    return filteredRequests;
  }
}
