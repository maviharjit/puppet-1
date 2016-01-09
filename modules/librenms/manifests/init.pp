# puppet class to manage LibreNMS installs

class librenms (
	$dir = "/opt/librenms",
	$user = "librenms",
	$group = "librenms",
	$www_group = "www-data",
	$repo = "https://github.com/librenms/librenms.git",
	$vhost,
	$vhost_aliases = [],
) {
	include librenms::packages
	group { $group:
		ensure	=> present,
	}
	user { $user:
		ensure	=> present,
		comment	=> "LibreNMS",
		home	=> $dir,
		group	=> $group,
		groups	=> [ $www_group ],
		require	=> [ Class["librenms::packages"], ],
	}
	file { $dir:
		ensure	=> directory,
		replace	=> false,
		recurse	=> true,
		owner	=> $user,
		group	=> $group,
		require	=> [ User[$user], Group[$group], ],
	}
	file { "$dir/rrd":
		ensure	=> directory,
		owner	=> $user,
		group	=> $group,
		mode	=> "ug+rw",
		recurse	=> true,
	}
	file { "$dir/logs":
		ensure	=> directory,
		owner	=> $user,
		group	=> $www_group,
		mode	=> "ug+rw",
		recurse	=> true,
	}
	class { "librenms::install":
		dir	=> $dir,
		user	=> $user,
		group	=> $group,
	}
	class { "librenms::vhost":
		dnsname	=> $vhost,
		aliases	=> $vhost_aliases,
	}
}

class librenms::install (
	$dir,
	$user,
	$group,
) {
	exec { 'librenms::clone':
		command => "git clone $repo $dir",
		creates	=> "$dir/includes/defaults.inc.php",
		require	=> [ Class["librenms::packages"], File[$dir], ],
		user	=> $user,
		group	=> $group,
	}
}

class librenms::packages {

	include git
	include php5::mcrypt
	include snmp

	$common_pkgs = [

		"fping",
		"graphviz",
		"nmap",
		"php-pear",
		"rrdtool",

	]

	$deb_pkgs = [

		"imagemagick",
		"ipcalc",
		"ipmitool",
		"mtr-tiny",
		"mysql-client",
		"php5-curl",
		"php5-gd",
		"php5-json",
		"php5-mysql",
		"php5-snmp",
		"php5-xcache",
		"php-net-ipv4",
		"php-net-ipv6",
		"python-mysqldb",
		"sipcalc",
		"snmp",
		"whois",

	]
	$centos_pkgs = [

		"ImageMagick",
		"jwhois",
		"mysql",
		"net-snmp-utils",
		"OpenIPMI-tools",
		"php-gd",
		"php-mysql",
		"php-pecl-apc",
		"php-snmp",

	]

	$ospkgs = $operatingsystem ? {
		Debian	=> $deb_pkgs,
		Ubuntu	=> $deb_pkgs,
		CentOS	=> $centos_pkgs,
	}
	package { $common_pkgs:
		ensure	=> installed,
	}
	package { $ospkgs:
		ensure	=> installed,
	}
}

# TODO:
# Update timezone in /etc/php5/apache2/php.ini and /etc/php5/cli/php.ini

# TODO: non-Debian/Ubuntu support
class librenms::vhost (
	$apachedir = "/etc/apache2",
	$apachever = "2.4",
	$dir,
	$dnsname,
	$aliases = [],
) {
	exec { "librenms::a2dissite-default":
		command	=> "a2dissite 000-default",
		onlyif	=> "test -d $apachedir/sites-enabled/000-default",
		notify	=> Exec["librenms::a2ensite"],
		refreshonly => true,
	}
	exec { "librenms::a2ensite":
		command => "a2ensite $dnsname.conf",
		notify	=> Class["apache::service"],
		refreshonly => true,
	}
	exec { "librenms::mod_rewrite":
		command => "a2enmod rewrite",
		notify	=> Exec["librenms::a2dissite-default"],
		refreshonly => true,
	}
	file { "$apachedir/sites-available/$dnsname.conf":
		ensure	=> present,
		content	=> template("librenms/librenms-apache.erb"),
		owner	=> "root",
		group	=> "root",
		mode	=> 0644,
		require	=> Class["librenms::install"],
		notify	=> Exec["librenms::mod_rewrite"],
	}
}

class librenms::mysql::dump {
	ulb { "librenms-mysql-dump":
		source_class	=> "librenms",
	}
	cron_job { "librenms-mysql-dump":
		interval	=> "daily",
		script		=> "#!/bin/sh
# Generated by puppet - do not edit here
/usr/local/bin/librenms-mysql-dump
",
	}
}

