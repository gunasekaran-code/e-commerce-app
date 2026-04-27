import 'package:flutter/material.dart';

// ===== Brand Colors =====
const Color kBrandRed = Color(0xFFE4252A);
const Color kBrandRedDark = Color(0xFFB81E22);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);
const Color kSurface = Color(0xFFF7F7F9);
const Color kCardBorder = Color(0xFFEDEDF0);

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const ProfilePage({super.key, required this.userData});

  String get _fullName => (userData['full_name'] ?? userData['name'] ?? 'User').toString();
  String get _email => (userData['email'] ?? 'No email').toString();
  String get _phone => (userData['phone'] ?? '+1 000 000 0000').toString();
  String get _initial =>
      _fullName.trim().isNotEmpty ? _fullName.trim()[0].toUpperCase() : 'U';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 0),
              _buildStatsRow(),
              _buildSectionTitle('Account'),
              _buildActionGroup([
                _ActionItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal info',
                  onTap: () {
                   
                  },
                ),
                _ActionItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy & Security',
                  subtitle: 'Password, 2FA, sessions',
                  onTap: () {},
                ),
                _ActionItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Manage alerts and sounds',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 35),
              _buildSectionTitle('Preferences'),
              _buildActionGroup([
                _ActionItem(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Theme and display',
                  onTap: () {},
                ),
                _ActionItem(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'English (US)',
                  onTap: () {},
                ),
                _ActionItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  subtitle: 'FAQs and contact us',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 28),
              _buildLogoutButton(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Header with red gradient =====
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBrandRed, kBrandRedDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // _circleIconButton(Icons.arrow_back_ios_new_rounded, () {
                  //   Navigator.maybePop(context);
                  // }),
                  const Text(
                    'My Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // _circleIconButton(Icons.settings_outlined, () {}),
                ],
              ),
              const SizedBox(height: 28),
              // Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  child: Text(
                    _initial,
                    style: const TextStyle(
                      fontSize: 36,
                      color: kBrandRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mail_outline_rounded,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _email,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  // ===== Stats card (overlapping the header) =====
  Widget _buildStatsRow() {
    return Transform.translate(
      offset: const Offset(0, -40),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _statTile(Icons.bolt_rounded, '128', 'Activity'),
            _divider(),
            _statTile(Icons.favorite_border_rounded, '46', 'Favorites'),
            _divider(),
            _statTile(Icons.emoji_events_outlined, '12', 'Awards'),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: kCardBorder,
      );

  Widget _statTile(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: kBrandRed, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: kTextDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: kTextMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ===== Section title =====
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: kTextDark,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // ===== Action group card =====
  Widget _buildActionGroup(List<_ActionItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kCardBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i != items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: kCardBorder),
              ),
          ],
        ],
      ),
    );
  }

  // ===== Logout =====
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [kBrandRed, kBrandRedDark],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: kBrandRed.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/LoginPage', (route) => false);
            },
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===== Reusable action item =====
class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kBrandRed.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: kBrandRed, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: kTextDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          color: kTextMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: kTextMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
