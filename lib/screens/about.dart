import 'package:flutter/material.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/widgets/CustomAppBar.dart'; // تأكد من المسار الصحيح

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context); // للترجمة

    // لتحديد ما إذا كانت الشاشة كبيرة (ويب) أو صغيرة (موبايل)
    final bool isWeb = MediaQuery.of(context).size.width > 950;

    // دالة مساعدة لترجمة النصوص
    String localizedStrings(String key) => localizations.translate(key);

    return Scaffold(
      appBar: const CustomAppBar(), // الـ CustomAppBar يستمد الثيم تلقائياً
      body: Center(
        // لكي يكون المحتوى في المنتصف على الشاشات الكبيرة
        child: Container(
          constraints: const BoxConstraints(
              maxWidth: 900), // تحديد عرض أقصى للمحتوى على الويب
          padding: EdgeInsets.all(isWeb ? 32.0 : 16.0), // هامش أكبر على الويب
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان الرئيسي
                Text(
                  localizedStrings('about_title'),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    // حجم أكبر للعنوان الرئيسي
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary, // لون الثيم الأساسي
                  ),
                  textAlign: isWeb
                      ? TextAlign.center
                      : TextAlign.start, // توسيط على الويب
                ),
                SizedBox(height: isWeb ? 24 : 16), // مسافة أكبر على الويب

                // وصف التطبيق
                Text(
                  localizedStrings('about_description'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: isWeb
                      ? TextAlign.center
                      : TextAlign.start, // توسيط على الويب
                ),
                SizedBox(height: isWeb ? 48 : 32),

                // قسم الميزات (تم تغيير بعض الميزات)
                Text(
                  localizedStrings('features_title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    // عنوان قسم الميزات
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: isWeb ? TextAlign.center : TextAlign.start,
                ),
                SizedBox(height: isWeb ? 24 : 16),

                // عرض الميزات في GridView على الويب، أو Column على الموبايل
                isWeb
                    ? GridView.count(
                        crossAxisCount: 2, // عمودين على الويب
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(), // لمنع الـ scroll داخل الـ grid
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio:
                            4, // نسبة العرض للارتفاع لكل عنصر في الـ grid
                        children: [
                          _buildFeatureItem(context,
                              localizedStrings('feature1_new'), Icons.flash_on),
                          _buildFeatureItem(context,
                              localizedStrings('feature2_new'), Icons.security),
                          _buildFeatureItem(
                              context,
                              localizedStrings('feature3_new'),
                              Icons.track_changes),
                          _buildFeatureItem(
                              context,
                              localizedStrings('feature4_new'),
                              Icons.support_agent),
                          _buildFeatureItem(context,
                              localizedStrings('feature5_new'), Icons.payment),
                        ],
                      )
                    : Column(
                        children: [
                          _buildFeatureItem(context,
                              localizedStrings('feature1_new'), Icons.flash_on),
                          _buildFeatureItem(context,
                              localizedStrings('feature2_new'), Icons.security),
                          _buildFeatureItem(
                              context,
                              localizedStrings('feature3_new'),
                              Icons.track_changes),
                          _buildFeatureItem(
                              context,
                              localizedStrings('feature4_new'),
                              Icons.support_agent),
                          _buildFeatureItem(context,
                              localizedStrings('feature5_new'), Icons.payment),
                        ],
                      ),
                SizedBox(height: isWeb ? 48 : 32),

                // لماذا تختارنا؟ (تم تغيير المحتوى)
                Text(
                  localizedStrings('why_choose_title_new'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: isWeb ? TextAlign.center : TextAlign.start,
                ),
                SizedBox(height: isWeb ? 24 : 16),
                Text(
                  localizedStrings('why_choose_description_new'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: isWeb ? TextAlign.center : TextAlign.start,
                ),
                SizedBox(height: isWeb ? 48 : 32),

                // فريق العمل
                Text(
                  localizedStrings('team_title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: isWeb ? TextAlign.center : TextAlign.start,
                ),
                SizedBox(height: isWeb ? 24 : 16),

                // عرض أعضاء الفريق في GridView على الويب، أو Column على الموبايل
                isWeb
                    ? GridView.count(
                        crossAxisCount: 2, // ثلاثة أعمدة على الويب
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        children: [
                          _buildTeamMemberCard(
                            context,
                            localizedStrings('founder_name'),
                            localizedStrings('founder_role'),
                            localizedStrings('founder_bio'),
                          ),
                          _buildTeamMemberCard(
                            context,
                            localizedStrings('marketing_name'),
                            localizedStrings('marketing_role'),
                            localizedStrings('marketing_bio'),
                          )
                        ],
                      )
                    : Column(
                        children: [
                          _buildTeamMemberCard(
                            context,
                            localizedStrings('founder_name'),
                            localizedStrings('founder_role'),
                            localizedStrings('founder_bio'),
                          ),
                          _buildTeamMemberCard(
                            context,
                            localizedStrings('marketing_name'),
                            localizedStrings('marketing_role'),
                            localizedStrings('marketing_bio'),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // تم تغيير اسم الدالة وخصائصها لتعكس الميزات الجديدة
  Widget _buildFeatureItem(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2, // ظل خفيف
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: theme.cardColor, // لون الكارد
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon,
                color: theme.colorScheme.secondary,
                size: 30), // أيقونة بلون ثانوي بارز
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500, // خط سميك قليلاً
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(
      BuildContext context, String name, String role, String bio) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardColor, // تطبيق لون الكارد من الثيم
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // تغيير Row إلى Column لتناسب الشاشات الصغيرة والكبيرة بشكل أفضل
          crossAxisAlignment: CrossAxisAlignment.center, // توسيط المحتوى
          children: [
            CircleAvatar(
              radius: 40, // حجم أكبر للـ Avatar
              backgroundColor: theme.colorScheme.primary
                  .withOpacity(0.8), // لون أساسي باهت قليلاً
              child: Text(
                name.isNotEmpty
                    ? name.substring(0, 1).toUpperCase()
                    : '', // الحرف الأول كبير
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimary, // لون النص على primary
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              role,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary, // لون الدور بلون ثانوي
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              bio,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme
                    .colorScheme.onSurfaceVariant, // لون الـ bio كلون ثانوي
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
