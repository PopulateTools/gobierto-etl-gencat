# frozen_string_literal: true

class Alpha2

  DATA = {
    "Tajikistan" => "TJ",
    "Jamaica" => "JM",
    "Haiti" => "HT",
    "Sao Tome and Principe" => "ST",
    "Montserrat" => "MS",
    "United Arab Emirates" => "AE",
    "Pakistan" => "PK",
    "Netherlands" => "NL",
    "Luxembourg" => "LU",
    "Belize" => "BZ",
    "Iran (Islamic Republic of)" => "IR",
    "Bolivia (Plurinational State of)" => "BO",
    "Uruguay" => "UY",
    "Ghana" => "GH",
    "Saudi Arabia" => "SA",
    "Côte d'Ivoire" => "CI",
    "Saint Martin (French part)" => "MF",
    "French Southern Territories" => "TF",
    "Anguilla" => "AI",
    "Qatar" => "QA",
    "Sint Maarten (Dutch part)" => "SX",
    "Libya" => "LY",
    "Bouvet Island" => "BV",
    "Papua New Guinea" => "PG",
    "Kyrgyzstan" => "KG",
    "Equatorial Guinea" => "GQ",
    "Western Sahara" => "EH",
    "Niue" => "NU",
    "Puerto Rico" => "PR",
    "Grenada" => "GD",
    "Korea (Republic of)" => "KR",
    "South Korea" => "KR",
    "Heard Island and McDonald Islands" => "HM",
    "San Marino" => "SM",
    "Sierra Leone" => "SL",
    "Congo (Democratic Republic of the)" => "CD",
    "Macedonia (the former Yugoslav Republic of)" => "MK",
    "Turkey" => "TR",
    "Algeria" => "DZ",
    "Georgia" => "GE",
    "Palestine, State of" => "PS",
    "Barbados" => "BB",
    "Ukraine" => "UA",
    "Guadeloupe" => "GP",
    "French Polynesia" => "PF",
    "Namibia" => "NA",
    "Botswana" => "BW",
    "Syrian Arab Republic" => "SY",
    "Togo" => "TG",
    "Dominican Republic" => "DO",
    "Antarctica" => "AQ",
    "Switzerland" => "CH",
    "Madagascar" => "MG",
    "Faroe Islands" => "FO",
    "Virgin Islands (British)" => "VG",
    "Gibraltar" => "GI",
    "Brunei Darussalam" => "BN",
    "Lao People's Democratic Republic" => "LA",
    "Iceland" => "IS",
    "Estonia" => "EE",
    "United States Minor Outlying Islands" => "UM",
    "Lithuania" => "LT",
    "Serbia" => "RS",
    "Mauritania" => "MR",
    "Andorra" => "AD",
    "Hungary" => "HU",
    "Tokelau" => "TK",
    "Malaysia" => "MY",
    "Angola" => "AO",
    "Cabo Verde" => "CV",
    "Norfolk Island" => "NF",
    "Panama" => "PA",
    "Guinea-Bissau" => "GW",
    "Belgium" => "BE",
    "Portugal" => "PT",
    "United Kingdom of Great Britain and Northern Ireland" => "GB",
    "United Kingdom" => "GB",
    "Isle of Man" => "IM",
    "United States of America" => "US",
    "United States" => "US",
    "Yemen" => "YE",
    "Hong Kong" => "HK",
    "Azerbaijan" => "AZ",
    "Cocos (Keeling) Islands" => "CC",
    "Mali" => "ML",
    "Slovakia" => "SK",
    "Vanuatu" => "VU",
    "Timor-Leste" => "TL",
    "Croatia" => "HR",
    "Suriname" => "SR",
    "Mauritius" => "MU",
    "Czech Republic" => "CZ",
    "Saint Pierre and Miquelon" => "PM",
    "Lesotho" => "LS",
    "Samoa" => "WS",
    "Comoros" => "KM",
    "Italy" => "IT",
    "Burundi" => "BI",
    "Wallis and Futuna" => "WF",
    "Guinea" => "GN",
    "Singapore" => "SG",
    "Colombia" => "CO",
    "China" => "CN",
    "Aruba" => "AW",
    "Morocco" => "MA",
    "Finland" => "FI",
    "Holy See" => "VA",
    "Zimbabwe" => "ZW",
    "Cayman Islands" => "KY",
    "Bahrain" => "BH",
    "Paraguay" => "PY",
    "Ecuador" => "EC",
    "Liberia" => "LR",
    "Russian Federation" => "RU",
    "Russia" => "RU",
    "Poland" => "PL",
    "Oman" => "OM",
    "Malta" => "MT",
    "South Sudan" => "SS",
    "Germany" => "DE",
    "Turkmenistan" => "TM",
    "Svalbard and Jan Mayen" => "SJ",
    "Myanmar" => "MM",
    "Trinidad and Tobago" => "TT",
    "Israel" => "IL",
    "Bangladesh" => "BD",
    "Nauru" => "NR",
    "Sri Lanka" => "LK",
    "Uganda" => "UG",
    "Nigeria" => "NG",
    "Bonaire, Sint Eustatius and Saba" => "BQ",
    "Mexico" => "MX",
    "Curaçao" => "CW",
    "Slovenia" => "SI",
    "Mongolia" => "MN",
    "Canada" => "CA",
    "Åland Islands" => "AX",
    "Viet Nam" => "VN",
    "Taiwan, Province of China" => "TW",
    "Japan" => "JP",
    "British Indian Ocean Territory" => "IO",
    "Romania" => "RO",
    "Bulgaria" => "BG",
    "Guam" => "GU",
    "Brazil" => "BR",
    "Armenia" => "AM",
    "Zambia" => "ZM",
    "Djibouti" => "DJ",
    "Jersey" => "JE",
    "Austria" => "AT",
    "Cameroon" => "CM",
    "Sweden" => "SE",
    "Fiji" => "FJ",
    "Kazakhstan" => "KZ",
    "Greenland" => "GL",
    "Guyana" => "GY",
    "Christmas Island" => "CX",
    "Malawi" => "MW",
    "Tunisia" => "TN",
    "South Africa" => "ZA",
    "Tonga" => "TO",
    "Cyprus" => "CY",
    "Maldives" => "MV",
    "Pitcairn" => "PN",
    "Rwanda" => "RW",
    "Nicaragua" => "NI",
    "Saint Kitts and Nevis" => "KN",
    "Benin" => "BJ",
    "Ethiopia" => "ET",
    "Gambia" => "GM",
    "Tanzania, United Republic of" => "TZ",
    "Saint Vincent and the Grenadines" => "VC",
    "Falkland Islands (Malvinas)" => "FK",
    "Sudan" => "SD",
    "Monaco" => "MC",
    "Australia" => "AU",
    "Chile" => "CL",
    "Denmark" => "DK",
    "France" => "FR",
    "Turks and Caicos Islands" => "TC",
    "Cuba" => "CU",
    "Albania" => "AL",
    "Mozambique" => "MZ",
    "Bahamas" => "BS",
    "Niger" => "NE",
    "Guatemala" => "GT",
    "Liechtenstein" => "LI",
    "Nepal" => "NP",
    "Burkina Faso" => "BF",
    "Palau" => "PW",
    "Kuwait" => "KW",
    "India" => "IN",
    "Gabon" => "GA",
    "Tuvalu" => "TV",
    "Macao" => "MO",
    "Saint Helena, Ascension and Tristan da Cunha" => "SH",
    "Moldova (Republic of)" => "MD",
    "Cook Islands" => "CK",
    "Argentina" => "AR",
    "Seychelles" => "SC",
    "Ireland" => "IE",
    "Spain" => "ES",
    "Lebanon" => "LB",
    "Bermuda" => "BM",
    "Réunion" => "RE",
    "Kiribati" => "KI",
    "Antigua and Barbuda" => "AG",
    "Martinique" => "MQ",
    "El Salvador" => "SV",
    "Jordan" => "JO",
    "Thailand" => "TH",
    "Somalia" => "SO",
    "Marshall Islands" => "MH",
    "Congo" => "CG",
    "Korea (Democratic People's Republic of)" => "KP",
    "French Guiana" => "GF",
    "Bosnia and Herzegovina" => "BA",
    "Mayotte" => "YT",
    "South Georgia and the South Sandwich Islands" => "GS",
    "Kenya" => "KE",
    "Peru" => "PE",
    "Bhutan" => "BT",
    "Swaziland" => "SZ",
    "Costa Rica" => "CR",
    "Chad" => "TD",
    "Dominica" => "DM",
    "New Caledonia" => "NC",
    "Greece" => "GR",
    "Guernsey" => "GG",
    "Honduras" => "HN",
    "Virgin Islands (U.S.)" => "VI",
    "Central African Republic" => "CF",
    "Senegal" => "SN",
    "Afghanistan" => "AF",
    "Northern Mariana Islands" => "MP",
    "Philippines" => "PH",
    "Belarus" => "BY",
    "Latvia" => "LV",
    "Norway" => "NO",
    "Egypt" => "EG",
    "Cambodia" => "KH",
    "Iraq" => "IQ",
    "Saint Lucia" => "LC",
    "New Zealand" => "NZ",
    "Saint Barthélemy" => "BL",
    "Uzbekistan" => "UZ",
    "Indonesia" => "ID",
    "Eritrea" => "ER",
    "Venezuela (Bolivarian Republic of)" => "VE",
    "Micronesia (Federated States of)" => "FM",
    "Solomon Islands" => "SB",
    "Montenegro" => "ME",
    "American Samoa" => "AS"
  }

  def self.find_by_country_name(country_name)
    DATA[country_name]
  end

end
