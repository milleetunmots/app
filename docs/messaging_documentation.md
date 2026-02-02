# Documentation - Envoi de Messages SMS

Cette documentation décrit l'architecture d'envoi de SMS via les deux fournisseurs disponibles : **SpotHit** (par défaut) et **Aircall**.

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [SpotHit - Fournisseur par défaut](#spothit---fournisseur-par-défaut)
3. [Aircall - Fournisseur alternatif](#aircall---fournisseur-alternatif)
4. [Orchestrateur principal : ProgramMessageService](#orchestrateur-principal--programmessageservice)
5. [Suivi des statuts](#suivi-des-statuts)
6. [Webhooks](#webhooks)
7. [Variables de personnalisation](#variables-de-personnalisation)
8. [Configuration](#configuration)
9. [Comparatif des deux fournisseurs](#comparatif-des-deux-fournisseurs)

---

## Vue d'ensemble

L'application utilise une architecture unifiée pour l'envoi de SMS avec deux fournisseurs :

```
┌─────────────────────────────────────────────────────────────┐
│                   ProgramMessageService                      │
│              (Orchestrateur principal)                       │
└─────────────────────┬───────────────────────────────────────┘
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
┌─────────────────────┐   ┌─────────────────────┐
│      SpotHit        │   │      Aircall        │
│   (par défaut)      │   │   (alternatif)      │
│                     │   │                     │
│ - SMS en masse      │   │ - SMS individuels   │
│ - MMS               │   │ - Lié aux appels    │
│ - Variables         │   │ - Max 1600 car.     │
└─────────────────────┘   └─────────────────────┘
```

---

## SpotHit - Fournisseur par défaut

### Quand l'utiliser ?

- Envoi de SMS en masse à plusieurs destinataires
- Messages programmés avec personnalisation (variables)
- Support des SMS longs
- MMS avec pièces jointes (expérimental)
- Tout envoi général de messages

### Service principal

**Fichier** : `app/services/spot_hit/send_sms_service.rb`

```ruby
# Exemple d'utilisation - SMS simple à plusieurs destinataires
SpotHit::SendSmsService.new(
  [parent1_id, parent2_id],           # Destinataires (IDs des parents)
  Time.zone.now.to_i,                 # Timestamp d'envoi
  "Votre message ici"                 # Contenu du message
).call

# Exemple avec variables personnalisées
SpotHit::SendSmsService.new(
  { parent1_id => { 'PRENOM_ENFANT' => 'Jean' } },
  Time.zone.now.to_i,
  "Bonjour, {PRENOM_ENFANT} progresse bien !"
).call
```

### API SpotHit

**Endpoint** : `https://www.spot-hit.fr/api/envoyer/sms`

**Paramètres envoyés** :
```ruby
{
  'key' => ENV['SPOT_HIT_API_KEY'],      # Clé API
  'destinataires' => {},                  # Numéros de téléphone
  'message' => @message,                  # Contenu du message
  'date' => @planned_timestamp,           # Date d'envoi programmée
  'destinataires_type' => 'datas',
  'smslong' => 1                          # Support SMS longs
}
```

### Flux d'envoi SpotHit

```
Admin → ProgramMessageService
          ↓
    Validation des destinataires
          ↓
    SpotHit::SendSmsService
          ↓
    POST vers SpotHit API
          ↓
    Création Events::TextMessage
    (spot_hit_status = 0 "En attente")
          ↓
    Webhook de statut reçu
          ↓
    Mise à jour du statut
```

---

## Aircall - Fournisseur alternatif

### Quand l'utiliser ?

- Messagerie individuelle avec un accompagnant spécifique
- SMS liés aux appels (call0_goals, etc.)
- Quand l'utilisateur admin a un `aircall_number_id` configuré
- Messages nécessitant un suivi détaillé

### Prérequis

- L'utilisateur admin doit avoir un `aircall_number_id` assigné
- La variable `AIRCALL_MESSAGE_ENABLED` doit être définie
- Limite de 1600 caractères par message

### Service principal

**Fichier** : `app/services/aircall/send_message_service.rb`

```ruby
# Utilisation via le job (recommandé)
Aircall::SendMessageJob.perform_later(
  aircall_number_id,      # ID du numéro Aircall
  parent.phone_number,    # Numéro du destinataire
  "Votre message",        # Contenu
  event.id                # ID de l'événement associé
)

# Utilisation directe du service
Aircall::SendMessageService.new(
  number_id: aircall_number_id,
  to: "+33612345678",
  body: "Votre message",
  event_id: event.id
).call
```

### API Aircall

**Endpoint** : `https://api.aircall.io/v1/numbers/{number_id}/messages/native/send`

**Authentification** : HTTP Basic Auth
```ruby
TOKEN_ID = ENV.fetch('AIRCALL_API_ID')
TOKEN_PASSWORD = ENV.fetch('AIRCALL_API_TOKEN')
```

### Flux d'envoi Aircall

```
Admin → ProgramMessageService
          ↓
    Validation (1 destinataire, 1600 car. max)
          ↓
    Création Event (message_provider='aircall')
          ↓
    Planification Aircall::SendMessageJob
          ↓
    Exécution du job à l'heure prévue
          ↓
    POST vers Aircall API
          ↓
    Mise à jour Event (spot_hit_status = 2)
          ↓
    Webhook de statut reçu
          ↓
    Mise à jour finale (1=livré, 4=échec)
```

---

## Orchestrateur principal : ProgramMessageService

**Fichier** : `app/services/program_message_service.rb`

Ce service unifie l'envoi de messages quel que soit le fournisseur.

### Paramètres d'initialisation

```ruby
ProgramMessageService.new(
  planned_date,           # Date d'envoi (ex: "2024-01-15")
  planned_hour,           # Heure d'envoi (ex: "14:30")
  recipients,             # Destinataires (IDs, tags, groupes)
  message,                # Contenu du message
  file = nil,             # Fichier joint (MMS)
  redirection_target_id,  # ID cible de redirection (liens trackés)
  quit_message = false,   # Message de désabonnement
  workshop_id = nil,      # ID atelier associé
  supporter = nil,        # Accompagnant
  group_status = ['active'], # Filtrage par statut
  provider = 'spothit',   # Fournisseur ('spothit' ou 'aircall')
  aircall_number_id = nil # ID numéro Aircall (requis si provider='aircall')
)
```

### Sélection automatique du fournisseur

```ruby
# Dans l'interface admin
provider = if params[:call_goals_sms] == 'call0_goals' &&
              params[:provider] == 'aircall' &&
              current_admin_user.aircall_number_id
  'aircall'
else
  'spothit'  # Par défaut
end
```

### Validation des destinataires

Le service effectue plusieurs filtres :
1. Filtrage par accompagnant assigné
2. Filtrage par statut de groupe (active, waiting, etc.)
3. Validation de la validité parent/enfant
4. Vérification des numéros de téléphone

---

## Suivi des statuts

### Codes de statut (communs aux deux fournisseurs)

| Code | Libellé | Description |
|------|---------|-------------|
| 0 | En attente | Message programmé, pas encore envoyé |
| 1 | Livré | Message reçu par le destinataire |
| 2 | Envoyé | Message envoyé (en transit) |
| 3 | En cours | Envoi en cours |
| 4 | Échec | Échec de livraison |
| 5 | Expiré | Message expiré |

### Modèle Event (suivi unifié)

```ruby
# app/models/events/text_message.rb
class Events::TextMessage < Event
  # Champs de suivi
  # - spot_hit_status: integer (0-5)
  # - spot_hit_message_id: string (ID campagne SpotHit)
  # - aircall_message_id: string (ID message Aircall)
  # - message_provider: string ('aircall' ou 'spot_hit')
end
```

### Modèle AircallMessage (suivi spécifique Aircall)

```ruby
# app/models/aircall_message.rb
# Champs :
# - aircall_id: identifiant unique Aircall
# - parent_id: destinataire
# - caller_id: AdminUser expéditeur
# - body: contenu du message
# - status: 'sent', 'delivered', 'received'
# - direction: 'inbound' ou 'outbound'
```

---

## Webhooks

### SpotHit

| Endpoint | Description |
|----------|-------------|
| `PUT /events/:id/update_status` | Mise à jour statut de livraison |
| `POST /events/spot_hit_stop` | Réception commande STOP |
| `POST /events/spot_hit_response` | Réception réponse parent |

### Aircall

| Endpoint | Token ENV |
|----------|-----------|
| `POST /aircall/messages` | `AIRCALL_WEBHOOK_MESSAGE_TOKEN` |
| `POST /aircall/calls` | `AIRCALL_WEBHOOK_CALL_TOKEN` |
| `POST /aircall/events_messages_status_updated` | `AIRCALL_WEBHOOK_EVENT_MESSAGE_STATUS_UPDATED_TOKEN` |

---

## Variables de personnalisation

Variables disponibles dans les messages :

| Variable | Description |
|----------|-------------|
| `{PRENOM_ENFANT}` | Prénom de l'enfant |
| `{URL}` | URL de redirection trackée |
| `{PRENOM_ACCOMPAGNANTE}` | Prénom de l'accompagnant |
| `{NUMERO_AIRCALL_ACCOMPAGNANTE}` | Numéro Aircall de l'accompagnant |
| `{PARENT_SECURITY_TOKEN}` | Token de sécurité du parent |
| `{PARENT_ADDRESS}` | Adresse complète du parent |

**Exemple** :
```
Bonjour ! {PRENOM_ENFANT} a une nouvelle vidéo à découvrir : {URL}
Pour toute question, contactez {PRENOM_ACCOMPAGNANTE} au {NUMERO_AIRCALL_ACCOMPAGNANTE}.
```

---

## Configuration

### Variables d'environnement SpotHit

```bash
# Authentification
SPOT_HIT_API_KEY=votre_cle_api
SPOT_HIT_AGENT_ID=votre_agent_id

# Sécurité (développement)
SPOT_HIT_SAFEGUARD=true
SAFE_PHONE_NUMBERS=+33612345678,+33698765432
```

### Variables d'environnement Aircall

```bash
# Authentification API
AIRCALL_API_ID=votre_api_id
AIRCALL_API_TOKEN=votre_api_token

# Activation
AIRCALL_ENABLED=true
AIRCALL_MESSAGE_ENABLED=true

# Webhooks
AIRCALL_WEBHOOK_MESSAGE_TOKEN=token_securise
AIRCALL_WEBHOOK_CALL_TOKEN=token_securise
AIRCALL_WEBHOOK_INSIGHT_CARDS_TOKEN=token_securise
AIRCALL_WEBHOOK_EVENT_MESSAGE_STATUS_UPDATED_TOKEN=token_securise
```

### Safeguard (protection en développement)

En environnement de développement ou avec `SPOT_HIT_SAFEGUARD=true`, seuls les numéros listés dans `SAFE_PHONE_NUMBERS` reçoivent les messages.

---

## Comparatif des deux fournisseurs

| Aspect | SpotHit | Aircall |
|--------|---------|---------|
| **Usage principal** | SMS en masse | SMS individuels |
| **Par défaut** | Oui | Non |
| **Destinataires** | Multiple | Un seul |
| **Longueur max** | Illimitée (SMS longs) | 1600 caractères |
| **MMS** | Oui | Non |
| **Variables** | Oui (via hash) | Non |
| **Suivi détaillé** | Event uniquement | Event + AircallMessage |
| **Prérequis admin** | Aucun | `aircall_number_id` requis |
| **Jobs** | Synchrone | Asynchrone (SendMessageJob) |

---

## Exemples d'utilisation courants

### 1. Envoi SMS simple via SpotHit

```ruby
# Depuis un controller ou service
ProgramMessageService.new(
  Date.today.to_s,
  "10:00",
  { parent_ids: [parent.id] },
  "Votre message ici",
  nil, nil, false, nil, nil,
  ['active'],
  'spothit'
).call
```

### 2. Envoi SMS via Aircall (call0_goals)

```ruby
ProgramMessageService.new(
  Date.today.to_s,
  "10:00",
  { parent_ids: [parent.id] },
  "Message de rappel d'objectifs",
  nil, nil, false, nil, supporter,
  ['active'],
  'aircall',
  current_admin_user.aircall_number_id
).call
```

### 3. Envoi direct via service SpotHit

```ruby
SpotHit::SendSmsService.new(
  parent_ids_array,
  1.hour.from_now.to_i,
  "Message programmé"
).call
```

### 4. Envoi direct via service Aircall

```ruby
Aircall::SendMessageService.new(
  number_id: admin_user.aircall_number_id,
  to: parent.phone_number,
  body: "Message direct",
  event_id: event.id
).call
```

---

## Gestion des erreurs

### Retry automatique (Aircall)

Le job `Aircall::SendMessageJob` gère les retries :
- Maximum 10 tentatives
- Délai exponentiel : 60 × (tentative + 1) minutes
- En cas d'échec final : statut mis à 4 (échec)

### Logging

Les erreurs sont enregistrées via Rollbar avec le contexte complet (statut API, message d'erreur, clés concernées).

---

## Fichiers principaux

| Fichier | Description |
|---------|-------------|
| `app/services/program_message_service.rb` | Orchestrateur principal |
| `app/services/spot_hit/send_sms_service.rb` | Envoi SMS SpotHit |
| `app/services/spot_hit/send_mms_service.rb` | Envoi MMS SpotHit |
| `app/services/aircall/send_message_service.rb` | Envoi SMS Aircall |
| `app/services/aircall/api_base.rb` | Client API Aircall |
| `app/jobs/aircall/send_message_job.rb` | Job asynchrone Aircall |
| `app/models/events/text_message.rb` | Modèle événement SMS |
| `app/models/aircall_message.rb` | Modèle message Aircall |
| `app/controllers/aircall_controller.rb` | Webhooks Aircall |
| `app/controllers/events_controller.rb` | Webhooks SpotHit |