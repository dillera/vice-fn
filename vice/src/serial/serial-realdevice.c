/*
 * serial-realdevice.c
 *
 * Written by
 *  Andreas Boose <viceteam@t-online.de>
 *
 * This file is part of VICE, the Versatile Commodore Emulator.
 * See README for copyright notice.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
 *  02111-1307  USA.
 *
 */

#include "vice.h"

#include "cmdline.h"
#include "lib.h"
#include "realdevice.h"
#include "resources.h"
#include "serial.h"
#include "traps.h"

/* Units 12-30 have no emulated device of their own. Enabling one with
   "RealDeviceN" sends its bus traffic to the real-device (OpenCBM) library,
   which may be a cable to real hardware or a bridge to a networked device
   such as FujiNet-PC. They are reached through the KERNAL traps. */
#define REALDEVICE_UNIT_FIRST   12
#define REALDEVICE_UNIT_LAST    30


int serial_realdevice_enable(void)
{
#ifdef HAVE_REALDEVICE
    return realdevice_enable();
#else
    return -1;
#endif
}

void serial_realdevice_disable(void)
{
#ifdef HAVE_REALDEVICE
    realdevice_disable();
#endif
}

#ifdef HAVE_REALDEVICE

static int realdevice_unit_enabled[REALDEVICE_UNIT_LAST + 1];

/* units chosen before the serial bus exists are attached by serial_realdevice_late_init() */
static int realdevice_units_ready = 0;

static int realdevice_unit_attach(unsigned int unit)
{
    if (serial_realdevice_enable() < 0) {
        return -1;
    }
    serial_device_type_set(SERIAL_DEVICE_REAL, unit);
    serial_device_get(unit)->inuse = 1;
    traps_device_enable(unit, 1);
    return 0;
}

static void realdevice_unit_detach(unsigned int unit)
{
    traps_device_enable(unit, 0);
    serial_device_get(unit)->inuse = 0;
    serial_device_type_set(SERIAL_DEVICE_NONE, unit);
    serial_realdevice_disable();
}

static int set_realdevice_unit(int val, void *param)
{
    unsigned int unit = vice_ptr_to_uint(param);
    int enable = val ? 1 : 0;

    if (enable == realdevice_unit_enabled[unit]) {
        return 0;
    }
    if (realdevice_units_ready) {
        if (enable) {
            if (realdevice_unit_attach(unit) < 0) {
                return -1;
            }
        } else {
            realdevice_unit_detach(unit);
        }
    }
    realdevice_unit_enabled[unit] = enable;
    return 0;
}

static resource_int_t resources_int[] = {
    { NULL, 0, RES_EVENT_NO, NULL,
      NULL, set_realdevice_unit, NULL },
    RESOURCE_INT_LIST_END
};

static cmdline_option_t cmdline_options[] =
{
    { NULL, SET_RESOURCE, CMDLINE_ATTRIB_NONE,
      NULL, NULL, NULL, (resource_value_t)1,
      NULL, "Use the real-device (OpenCBM) library for this device number" },
    { NULL, SET_RESOURCE, CMDLINE_ATTRIB_NONE,
      NULL, NULL, NULL, (resource_value_t)0,
      NULL, "Do not use the real-device (OpenCBM) library for this device number" },
    CMDLINE_LIST_END
};

int serial_realdevice_resources_init(void)
{
    unsigned int unit;

    for (unit = REALDEVICE_UNIT_FIRST; unit <= REALDEVICE_UNIT_LAST; unit++) {
        int rc;

        resources_int[0].name = lib_msprintf("RealDevice%u", unit);
        resources_int[0].value_ptr = &realdevice_unit_enabled[unit];
        resources_int[0].param = vice_uint_to_ptr(unit);
        rc = resources_register_int(resources_int);
        lib_free(resources_int[0].name);
        if (rc < 0) {
            return -1;
        }
    }
    return 0;
}

int serial_realdevice_cmdline_options_init(void)
{
    unsigned int unit;

    for (unit = REALDEVICE_UNIT_FIRST; unit <= REALDEVICE_UNIT_LAST; unit++) {
        int rc;

        cmdline_options[0].name = lib_msprintf("-realdevice%u", unit);
        cmdline_options[0].resource_name = lib_msprintf("RealDevice%u", unit);
        cmdline_options[1].name = lib_msprintf("+realdevice%u", unit);
        cmdline_options[1].resource_name = cmdline_options[0].resource_name;
        rc = cmdline_register_options(cmdline_options);
        lib_free(cmdline_options[0].name);
        lib_free(cmdline_options[0].resource_name);
        lib_free(cmdline_options[1].name);
        if (rc < 0) {
            return -1;
        }
    }
    return 0;
}

void serial_realdevice_late_init(void)
{
    unsigned int unit;

    realdevice_units_ready = 1;
    for (unit = REALDEVICE_UNIT_FIRST; unit <= REALDEVICE_UNIT_LAST; unit++) {
        if (realdevice_unit_enabled[unit] && realdevice_unit_attach(unit) < 0) {
            realdevice_unit_enabled[unit] = 0;
        }
    }
}

#else

int serial_realdevice_resources_init(void)
{
    return 0;
}

int serial_realdevice_cmdline_options_init(void)
{
    return 0;
}

void serial_realdevice_late_init(void)
{
}

#endif
