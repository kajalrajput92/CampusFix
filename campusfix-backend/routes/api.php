<?php

use Campusfix\Backend\Controllers\HealthController;
use Campusfix\Backend\Controllers\AuthController;
use Campusfix\Backend\Controllers\ComplaintController;
use Campusfix\Backend\Controllers\AdminController;
use Campusfix\Backend\Controllers\StaffController;
use Campusfix\Backend\Controllers\DepartmentController;
use Campusfix\Backend\Controllers\LocationController;
use Campusfix\Backend\Controllers\FeedbackController;
use Campusfix\Backend\Controllers\NotificationController;
use Campusfix\Backend\Controllers\ProfileController;
use Campusfix\Backend\Controllers\PasswordResetController;
return [

    // Health
    'GET /api/health' => [
        HealthController::class,
        'check'
    ],

    // Authentication
    'POST /api/auth/register' => [
        AuthController::class,
        'register'
    ],

    'POST /api/auth/login' => [
        AuthController::class,
        'login'
    ],
    // Password Recovery
'POST /api/auth/forgot-password' => [
    PasswordResetController::class,
    'forgotPassword'
],

'POST /api/auth/reset-password' => [
    PasswordResetController::class,
    'resetPassword'
],

    'GET /api/auth/me' => [
        AuthController::class,
        'me'
    ],

    // Complaint Management
    'POST /api/complaints' => [
        ComplaintController::class,
        'submit'
    ],

    'GET /api/complaints/my' => [
        ComplaintController::class,
        'myComplaints'
    ],
    'GET /api/complaints/show' => [
    ComplaintController::class,
    'show'
],
// Admin Management
'POST /api/admin/complaints/assign' => [
    AdminController::class,
    'assignComplaint'
],
// Staff Management
'GET /api/staff/complaints/my' => [
    StaffController::class,
    'myAssignments'
],
'PATCH /api/staff/complaints/status' => [
    StaffController::class,
    'updateComplaintStatus'
],
'GET /api/admin/dashboard/stats' => [
    AdminController::class,
    'dashboardStats'
],
'GET /api/admin/complaints' => [
    AdminController::class,
    'allComplaints'
],
'GET /api/admin/complaints/show' => [
    AdminController::class,
    'complaintDetails'
],
'GET /api/admin/staff' => [
    AdminController::class,
    'staffList'
],

'GET /api/admin/staff/show' => [
    AdminController::class,
    'staffDetails'
],

'PATCH /api/admin/staff/status' => [
    AdminController::class,
    'updateStaffStatus'
],
'GET /api/admin/departments' => [
    DepartmentController::class,
    'index'
],

'GET /api/admin/departments/show' => [
    DepartmentController::class,
    'show'
],

'POST /api/admin/departments' => [
    DepartmentController::class,
    'store'
],

'PATCH /api/admin/departments/update' => [
    DepartmentController::class,
    'update'
],
'GET /api/admin/locations' => [
    LocationController::class,
    'index'
],

'GET /api/admin/locations/show' => [
    LocationController::class,
    'show'
],

'POST /api/admin/locations' => [
    LocationController::class,
    'store'
],

'PATCH /api/admin/locations/update' => [
    LocationController::class,
    'update'
],

// Feedback Management
'POST /api/feedback' => [
    FeedbackController::class,
    'submit'
],

'GET /api/feedback/my' => [
    FeedbackController::class,
    'myFeedback'
],

'GET /api/admin/feedback' => [
    FeedbackController::class,
    'index'
],

'GET /api/admin/feedback/show' => [
    FeedbackController::class,
    'show'
],

'GET /api/admin/feedback/stats' => [
    FeedbackController::class,
    'stats'
],

// Notification Management
'GET /api/notifications' => [
    NotificationController::class,
    'index'
],

'GET /api/notifications/unread-count' => [
    NotificationController::class,
    'unreadCount'
],

'PATCH /api/notifications/read' => [
    NotificationController::class,
    'markAsRead'
],

'PATCH /api/notifications/read-all' => [
    NotificationController::class,
    'markAllAsRead'
],

'DELETE /api/notifications/delete' => [
    NotificationController::class,
    'delete'
],
// Profile Management
'GET /api/profile' => [
    ProfileController::class,
    'show'
],

'PATCH /api/profile' => [
    ProfileController::class,
    'update'
],

'PATCH /api/profile/password' => [
    ProfileController::class,
    'changePassword'
],

];
