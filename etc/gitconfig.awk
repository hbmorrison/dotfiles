BEGIN { USER_SECTION = 0; }
/^\[/ { if ( USER_SECTION == 1 ) { USER_SECTION = 0; } }
/^\[user\]/ { USER_SECTION = 1; }
{ if ( USER_SECTION == 1 ) { print; } }
