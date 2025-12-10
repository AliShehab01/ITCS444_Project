# flutter COURSE PROJECT

## Development of a Mobile App for Care Center

PROJECT TITLE:
Development of a Mobile App for Care Center
PROJECT MAIN GOAL:
Use Flutter Mobile App Development tools and techniques to create a Mobile-application. How can
you design and build a secure and user-friendly app designed to facilitate the rental, donation, and
exchange of essential mobility and medical equipment for the elderly and people with disabilities.
The app serves as a centralized, trusted source that connects individuals and organizations who
have equipment’s (e.g., wheelchairs, walkers, hospital beds, oxygen machines) with those in urgent
need of temporary or permanent use. By promoting reuse, reduces the financial burden on users
and minimizes waste, fostering a strong community support network.
PROJECT Domain:
The goal of this project is to design and build a mobile application, user-friendly mobile app (using
Flutter + Dart) that allows Care Societies and users to manage rental and donation processes for
assistive equipment (e.g., wheelchairs, crutches, walkers).
The app should allow administrators to add, categorize, and manage both rental requests and
donated items, while users can easily browse available equipment, reserve items, or submit
donation offers using their mobile devices.
The focus will be on developing key functionalities such as real-time inventory management,
reservations, return date tracking, automatic reminders, donation tracking, donor contributions,
follow-up notifications and usage reports.
1. Functional Requirements (must-implement):
1. User Authentication and Role Management:
o Develop a secure login system with role-based access control
(administrator/customer).
o Roles: Admin (Donor) , Renter, and Guest (browse only).
o Profile page (name, contact, ID, preferred contact method).
2. Inventory management
o Admin can add/edit/delete equipment: id, name, type, description, images, condition,
quantity, location, tags, availability Status, rental Price Per Day (optional).
COURSE PROJECT
2
o Set the status of each item (available, rented, donated, under maintenance).
o Browse/search/filter equipment by type, availability. Allow toggling between different
views.
3. Equipment reservations & rentals
Provide an intuitive interface for users to browse available equipment and make rental
requests.
o Renter can reserve equipment for specific date range or immediate pickup.
o Reservation flow: check availability → select dates → confirm → generate reservation
record.
o Admin accepts/declines reservations.
o Rental lifecycle: Reserved → Checked Out → Returned → Maintenance (if needed).
o Allow the app to auto-calculate rental duration/dates based for example on item type
or user type (trusted user, long term history). Allow the customer to change the
estimated date duration within a specific range.
o Allow customer to track application progress.
4. Donor Page and Donation Management:
o Add a dedicated Donor Page for individuals or organizations who wish to donate
assistive tools or equipment.
o Include a donation form where donors can specify the item type, condition, and select
photos or icons.
o Allow administrators to review and approve donations before adding them to the
inventory.
5. Tracking and Notifications System:
o Track the status and remaining duration of each rental (per item and per rental)
o Send automatic notifications to administrators and users when the return date is
approaching or overdue.
o Notify administrators about new donation submissions and equipment requiring
maintenance.
o Show current rentals and history for a user and for admin.
6. Reports and Statistics:
o Generate reports on most frequently rented and donated equipment.
o Provide administrators with usage analytics, overdue statistics, and maintenance
records.
o Offer insights for improving inventory and service efficiency.
7. Search and Filtering:
o Allow users to search for equipment using different parameters such as type, status, or
availability.
o Include filters for viewing only donated or rentable equipment.



OBJECTIVES
MARKS
Mark/Notes
1. User Authentication and Role Management:
o Develop a secure login system with role-based access control
(administrator/User).
1
2. Add View
o Admin can add/edit/delete equipment: id, name, type,
description, images, condition, quantity, location, tags,
availability Status, rental Price Per Day (optional).
o Allow toggling between different views.
2
3. Equipment Reservation/Rental (For Users):
o Renter can reserve equipment for specific date range or
immediate pickup.
o Reservation flow: check availability → select dates → confirm
→ generate reservation record.
o Admin accepts/declines reservations.
o Rental lifecycle: Reserved → Checked Out → Returned →
Maintenance (if needed).
o Allow the app to auto-calculate rental duration/dates based for
example on item type or user type (trusted user, long term
history). Allow the customer to change the estimated date
duration within a specific range.
o Allow customer to track application progress.
4
4. Donation Management (For Guests):
o Include a donation form where donors can specify the item
type, condition, and select photos or icons.
o Allow administrators to review and approve donations before
adding them to the inventory.
3
COURSE PROJECT
6
Required objectives for groups of thr
5. Tracking
o Track the status and remaining duration of each rental (per
item and per rental)
o Send automatic notifications to administrators and users when
the return date is approaching or overdue.
o Notify administrators about new donation submissions and
equipment requiring maintenance.
o Show current rentals and history for a user and for admin.
2
6. Reports and Statistics:
o Generate reports on rented and donated equipment.
o Provide administrators with usage analytics, overdue statistics,
and maintenance records.
o Offer insights for improving inventory and service efficiency.
1
7. Search and Filtering:
o Allow users to search for equipment using different
parameters such as type, status, or availability.
o Include filters for viewing only donated or rentable equipment
1
8. Notifications and overall system UI Design and process
implementation
• Aesthetics in the Design
• Visually pleasing UX design
• Use animation to enhance the look and feel of app.
• Extra Features