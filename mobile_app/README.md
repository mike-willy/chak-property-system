# mobile_app

A new Flutter project.

## Getting Started

## PROJECTED FIREBASE DATABASE

## Firestore Schema

```text
// Firestore Collections Structure
firestore/
├── users/
│   ├── {userId}
│   │   ├── name: string
│   │   ├── email: string
│   │   ├── phone: string
│   │   ├── role: "tenant" | "landlord" | "admin"
│   │   ├── profileImage: string
│   │   ├── createdAt: timestamp
│   │   └── isVerified: boolean
│
├── properties/
│   ├── {propertyId}
│   │   ├── title: string
│   │   ├── description: string
│   │   ├── address: {
│   │   │   ├── street: string
│   │   │   ├── city: string
│   │   │   ├── state: string
│   │   │   ├── zipCode: string
│   │   │   └── coordinates: geopoint
│   │   ├── }
│   │   ├── ownerId: string (ref: users)
│   │   ├── propertyType: "apartment" | "house" | "condo"
│   │   ├── price: number
│   │   ├── deposit: number
│   │   ├── bedrooms: number
│   │   ├── bathrooms: number
│   │   ├── squareFeet: number
│   │   ├── amenities: array
│   │   ├── images: array
│   │   ├── isAvailable: boolean
│   │   ├── createdAt: timestamp
│   │   └── updatedAt: timestamp
│
├── units/
│   ├── {unitId}
│   │   ├── propertyId: string (ref: properties)
│   │   ├── unitNumber: string
│   │   ├── floor: number
│   │   ├── features: array
│   │   ├── status: "vacant" | "occupied" | "maintenance"
│   │   └── availabilityDate: timestamp
│
├── applications/
│   ├── {applicationId}
│   │   ├── tenantId: string (ref: users)
│   │   ├── unitId: string (ref: units)
│   │   ├── status: "pending" | "approved" | "rejected"
│   │   ├── documents: array
│   │   ├── appliedDate: timestamp
│   │   ├── decisionDate: timestamp
│   │   └── notes: string
│
├── leases/
│   ├── {leaseId}
│   │   ├── tenantId: string (ref: users)
│   │   ├── unitId: string (ref: units)
│   │   ├── startDate: timestamp
│   │   ├── endDate: timestamp
│   │   ├── rentAmount: number
│   │   ├── paymentDueDay: number
│   │   ├── lateFee: number
│   │   ├── status: "active" | "expired" | "terminated"
│   │   └── signedDocument: string
│
├── payments/
│   ├── {paymentId}
│   │   ├── leaseId: string (ref: leases)
│   │   ├── tenantId: string (ref: users)
│   │   ├── amount: number
│   │   ├── method: "card" | "bank" | "mobile"
│   │   ├── status: "pending" | "completed" | "failed"
│   │   ├── transactionId: string
│   │   ├── dueDate: timestamp
│   │   ├── paidDate: timestamp
│   │   └── receiptUrl: string
│
├── maintenance/
│   ├── {requestId}
│   │   ├── tenantId: string (ref: users)
│   │   ├── unitId: string (ref: units)
│   │   ├── title: string
│   │   ├── description: string
│   │   ├── priority: "low" | "medium" | "high"
│   │   ├── status: "open" | "in-progress" | "completed"
│   │   ├── images: array
│   │   ├── createdAt: timestamp
│   │   └── updatedAt: timestamp
│
└── notifications/
    ├── {notificationId}
    │   ├── userId: string (ref: users)
    │   ├── title: string
    │   ├── body: string
    │   ├── type: "payment" | "application" | "maintenance"
    │   ├── isRead: boolean
    │   └── createdAt: timestamp