import '../models/etudiant.dart';
import '../models/presence.dart';
import '../models/seance.dart';
import '../config/constants.dart';

/// Static dummy data used when [AppConfig.useDummyData] == true.
/// Simulates the backend without a running server.
class DummyData {
  DummyData._();

  // ─── Séances ──────────────────────────────────────────────────────────────
  static final List<Seance> seances = [
    Seance(
      idSeance: 1,
      dateSeance: DateTime.now(),
      heureDebut: '08:00',
      heureFin: '10:00',
      idProf: 1,
      idModule: 1,
      idFiliere: 1,
      nomModule: 'Algorithmique',
      nomFiliere: 'Informatique L1',
      nomProf: 'Ahmed Benali',
    ),
    Seance(
      idSeance: 2,
      dateSeance: DateTime.now(),
      heureDebut: '10:00',
      heureFin: '12:00',
      idProf: 1,
      idModule: 2,
      idFiliere: 2,
      nomModule: 'Base de Données',
      nomFiliere: 'Informatique L2',
      nomProf: 'Ahmed Benali',
    ),
    Seance(
      idSeance: 3,
      dateSeance: DateTime.now().subtract(const Duration(days: 1)),
      heureDebut: '14:00',
      heureFin: '16:00',
      idProf: 1,
      idModule: 3,
      idFiliere: 1,
      nomModule: 'Réseaux',
      nomFiliere: 'Informatique L1',
      nomProf: 'Ahmed Benali',
    ),
    Seance(
      idSeance: 4,
      dateSeance: DateTime.now().add(const Duration(days: 1)),
      heureDebut: '08:00',
      heureFin: '10:00',
      idProf: 1,
      idModule: 1,
      idFiliere: 3,
      nomModule: 'Algorithmique',
      nomFiliere: 'Mathématiques L1',
      nomProf: 'Ahmed Benali',
    ),
  ];

  // ─── Étudiants ────────────────────────────────────────────────────────────
  static final List<Etudiant> etudiants = [
    // Filière 1
    const Etudiant(idEtudiant: 1, nom: 'Bouazza', prenom: 'Karim', idFiliere: 1),
    const Etudiant(idEtudiant: 2, nom: 'Laroui', prenom: 'Sara', idFiliere: 1),
    const Etudiant(idEtudiant: 3, nom: 'Amrani', prenom: 'Youssef', idFiliere: 1),
    const Etudiant(idEtudiant: 4, nom: 'Tazi', prenom: 'Nadia', idFiliere: 1),
    const Etudiant(idEtudiant: 5, nom: 'Chraibi', prenom: 'Omar', idFiliere: 1),
    const Etudiant(idEtudiant: 6, nom: 'Bensalem', prenom: 'Fatima', idFiliere: 1),
    // Filière 2
    const Etudiant(idEtudiant: 7, nom: 'Ouali', prenom: 'Hassan', idFiliere: 2),
    const Etudiant(idEtudiant: 8, nom: 'Naciri', prenom: 'Leila', idFiliere: 2),
    const Etudiant(idEtudiant: 9, nom: 'Berrada', prenom: 'Amine', idFiliere: 2),
    const Etudiant(idEtudiant: 10, nom: 'Fassi', prenom: 'Rim', idFiliere: 2),
    // Filière 3
    const Etudiant(idEtudiant: 11, nom: 'Sekkat', prenom: 'Mehdi', idFiliere: 3),
    const Etudiant(idEtudiant: 12, nom: 'Alami', prenom: 'Zineb', idFiliere: 3),
  ];

  // ─── Présences (mutable for demo CRUD) ───────────────────────────────────
  static List<Presence> presences = [
    const Presence(idPresence: 1, idSeance: 1, idEtudiant: 1, statut: Statut.present),
    const Presence(idPresence: 2, idSeance: 1, idEtudiant: 2, statut: Statut.absent),
    const Presence(idPresence: 3, idSeance: 1, idEtudiant: 3, statut: Statut.retard),
    const Presence(idPresence: 4, idSeance: 1, idEtudiant: 4, statut: Statut.justifie),
    const Presence(idPresence: 5, idSeance: 1, idEtudiant: 5, statut: Statut.present),
  ];
}
