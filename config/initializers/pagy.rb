# frozen_string_literal: true

# Pagy Variables
# See https://ddnexus.github.io/pagy/docs/api/pagy#variables

# Instance variables
Pagy::DEFAULT[:items] = 12

# Other Variables
Pagy::DEFAULT[:size] = 7 # nav bar links

# Extras
# See https://ddnexus.github.io/pagy/docs/extras

# Overflow extra: Allow for easy handling of overflow pages
# See https://ddnexus.github.io/pagy/docs/extras/overflow
require "pagy/extras/overflow"
Pagy::DEFAULT[:overflow] = :last_page

# Metadata extra: Provides the pagy_metadata hash for API responses
# See https://ddnexus.github.io/pagy/docs/extras/metadata
require "pagy/extras/metadata"

# Trim extra: Remove the page=1 param from links
# See https://ddnexus.github.io/pagy/docs/extras/trim
require "pagy/extras/trim"

# Limit extra: Allow the client to set items per page (renamed from 'items' in Pagy 9.x)
# See https://ddnexus.github.io/pagy/docs/extras/limit
require "pagy/extras/limit"
Pagy::DEFAULT[:limit_extra] = true
Pagy::DEFAULT[:limit_param] = :per_page
