# Copyright (c) 2026 Alexander Todorov <atodorov@otb.bg>
#
# Licensed under GNU Affero General Public License v3 or later (AGPLv3+)
# https://www.gnu.org/licenses/agpl-3.0.html

# pylint: disable=undefined-variable

import copy
from tcms.utils.secrets import get_secret


DATABASES["default"]["OPTIONS"]["sslmode"] = get_secret("KIWI_DB_SSL_MODE", "require")

DATABASES["postgres_17"] = copy.deepcopy(DATABASES["default"])
DATABASES["postgres_17"]["HOST"] = "postgres_17"

DATABASES["postgres_18"] = copy.deepcopy(DATABASES["default"])
DATABASES["postgres_18"]["HOST"] = "postgres_18"

# will be used for testing that plan/text DB connections are refused
DATABASES["plain_text"] = copy.deepcopy(DATABASES["default"])
DATABASES["plain_text"]["OPTIONS"]["sslmode"] = "disable"
