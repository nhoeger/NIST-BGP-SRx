/**
 * This software was developed at the National Institute of Standards and
 * Technology by employees of the Federal Government in the course of
 * their official duties. Pursuant to title 17 Section 105 of the United
 * States Code this software is not subject to copyright protection and
 * is in the public domain.
 *
 * NIST assumes no responsibility whatsoever for its use by other parties,
 * and makes no guarantees, expressed or implied, about its quality,
 * reliability, or any other characteristic.
 *
 * We would appreciate acknowledgment if the software is used.
 *
 * NIST ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS" CONDITION AND
 * DISCLAIM ANY LIABILITY OF ANY KIND FOR ANY DAMAGES WHATSOEVER RESULTING
 * FROM THE USE OF THIS SOFTWARE.
 *
 *
 * This software might use libraries that are under GNU public license or
 * other licenses. Please refer to the licenses of all libraries required
 * by this software.
 *
 * @version 0.6.2.1
 *
 * Changelog:
 * -----------------------------------------------------------------------------
 * 0.6.2.1  - 2024/08/24 - oborchert
 *            * Added defines to replace in code hardcoded strings.
 * 0.6.0.0  - 2021/06/26 - kyehwanl
 *            * Added as_relationship_data to configuration
 * 0.5.0.0  - 2017/07/05 - oborchert
 *            * Modified the newly added parameter version to router_protocol
 *            * Added more SCA configuration settings
 *          - 2017/06/16 - oborchert
 *            * BZ1061 fixed issue with platform dependent int type in libconfig
 * 0.3.0.10 - 2015/11/09 - oborchert
 *            * Removed types.h
 * 0.3.0    - 2014/11/17 - oborchert
 *            * Modified the function signature of initConfiguration
 *          - 2013/02/12 - oborchert
 *            * Added keepWindow to the configuration.
 *          - 2013/01/28 - oborchert
 *            * Added experimental mode parameters
 *            * Added mapping configuration
 * 0.2.0    - 2011/11/01 - oborchert
 *            * Extended.
 * 0.1.0    - 2009/12/23 - pgleichm
 *            * Code Created
 * -----------------------------------------------------------------------------
 */
#ifndef __CONFIGURATION_H__
#define __CONFIGURATION_H__

#include <stdbool.h>
#include <stdint.h>
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

#define SRX_DEF_CONSOLE_PASSWORD "x"
#define SRX_DEF_PORT             17900
#define SRX_DEF_CONSOLE_PORT     17901

#define MAX_PROXY_MAPPINGS 256

// CONFIG_INT will be set to int for 64 bit platform during configure. See
// configuration.ac - used for libconfig
#ifndef LCONFIG_INT
#define LCONFIG_INT long
#endif

/**
 * Destination for messages (errors, information).
 */
typedef enum {
  MSG_DEST_STDERR = 0,  ///< Write to Stderr
  MSG_DEST_FILENAME,    ///< Write to a log. file
  MSG_DEST_SYSLOG,      ///< Write to Syslog

  NUM_MSG_DEST          ///< Number of different message destinations
} MessagesDestination;

/**
 * Current configuration.
 */
typedef struct {
  /** The filename of this configuration. */
  char*                 configFileName;
  /** Verbose-mode (default: \c  false) */
  bool                  verbose;
  /** The level of verbose output (see log levels)*/
  int                   loglevel;
  char*                privateKey;
  char*                publicKey;
  /** Where should all messages go (default: MSG_DEST_STDERR) */
  MessagesDestination   msgDest;
  /** Send a synchronization request each time after a proxy connection is
   * established. This allows to process validation requests for updates
   * received by a router before a connection to SRx could be established. */
  bool                  syncAfterConnEstablished;

  /** Set only if \c msgDest is MSG_DEST_FILENAME */
  char*                 msgDestFilename;

  // SRx Server
  /** Port the SRx server should run on (default: 17900) */
  int                   server_port;
  /** Port for the server console (default: 17901) */
  int                   console_port;
  /** The console password */
  char*                 console_password;

  // RPKI
  /** Host name of the RPKI/Router protocol server */
  char*                 rpki_host;
  /** Port number of the RPKI/Router protocol server */
  int                   rpki_port;
  /* rpki router server protocol version number */
  int                   rpki_router_protocol;

  // BGPSec path validation
  /** Host name of the BGPSec protocol server */
  char*                 sca_configuration;
  /** Allow to synchronize the SCA log level with the one from srx-server.
   * REquires SCA to provide the capability to do so*/
  bool                  sca_sync_logging;
  
  char*                 as_relationship_data; // for aspa direction
  
  /** The minimum expected number of expected proxy clients */
  uint8_t               expectedProxies;
  // Experimental configurations
  /** If set true, disable the send queue. */
  bool                  mode_no_sendqueue;
  /** If set true, disable the receiver queue. */
  bool                  mode_no_receivequeue;

  /** The configured default keep window. Zero = deactivate.*/
  int                   defaultKeepWindow;
  /** the configuration array for the proxy mapping */
  uint32_t              mapping_routerID[256];
#ifdef USE_GRPC
  uint32_t              grpc_port;
#endif
} Configuration;

/**
 * Initialize the configuration with default values
 *
 * @param self the configuration instance
 */
void initConfiguration(Configuration* self);

/**
 * Frees all allocated resources.
 *
 * @param self Config. instance
 */
void releaseConfiguration(Configuration* self);

/**
 * Parse the given command line parameters. This function also is allowed to
 * only parse for the specification of a configuration file. This is -f/--file
 *
 * @param self The configuration object itself
 * @param argc The command line arguments.
 * @param argv The command line parameters.
 * @param onlyCfgFileName only parse for the configuration file.
 *
 * @return 1 = successful, 0 = invalid parameters found, -1 exit silent (for
 *         example -h)
 */
int parseProgramArgs(Configuration* self, int argc, const char** argv,
                     bool onlyCfgFileName);

/**
 * Reads a configuration file.
 *
 * @param self Config. instance that should be modified
 * @param filename Path and filename of the configuration file
 *
 * @return \c true = read and applied successfully, \c invalid or no file
 */
bool readConfigFile(Configuration* self, const char* filename);

/**
 * Checks if all necessary values are set.
 *
 * @param self Config. instance that should be checked
 *
 * @return \c true = yes, all necessary values are set, \c false = incomplete
 */
bool isCompleteConfiguration(Configuration* self);

#endif // !__CONFIGURATION_H__


