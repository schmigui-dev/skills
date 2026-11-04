# Domain Glossary

**Business language:** Spanish
**Code language:** English

## Context: Proposals
**Code location:** src/proposals/, db/

### Presupuesto
- **Code term:** Proposal
- **Definition:** Oferta comercial versionada que se envía al cliente para un evento.
- **Code names:** `Proposal`, `acceptProposal`, `proposals` (table)
- **Avoid:** `Quote`, `Offer`
- **Not the same as:** Reserva
- **Rules:** Only draft proposals can be accepted. An accepted proposal cannot be edited.
- **Examples:** Presupuesto v2 para un casamiento de 120 invitados.
- **Status:** confirmed
- **Sources:** user

### Reserva
- **Code term:** Booking
- **Definition:** Compromiso operativo de realizar el evento.
- **Code names:** `Booking`
- **Not the same as:** Presupuesto
- **Status:** draft
- **Sources:** user
- **Open questions:** ¿La reserva requiere seña pagada?

## Context: Staffing
**Code location:** src/staffing/

### Propuesta de turno
- **Code term:** ShiftProposal
- **Definition:** Esquema sugerido de turnos del personal para un evento.
- **Code names:** `ShiftProposal`, `proposeShift`
- **Not the same as:** Presupuesto
- **Status:** confirmed
- **Sources:** user
