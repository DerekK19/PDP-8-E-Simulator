/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2015 Bernhard Baehr
 *
 *	PC8Eiot.h - PC8-E Paper Tape Reader & Punch IOTs
 *
 *	This file is part of PDP-8/E Simulator.
 *
 *	PDP-8/E Simulator is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


extern void	i6010 (void);			/* RPE		6010	*/
extern void	i6011 (void);			/* RSF		6011	*/
extern unsigned s6011 (void);			/* RSF (skip test)	*/
extern void	i6012 (void);			/* RRB		6012	*/
extern void	i6014 (void);			/* RFC		6014	*/
extern void	i6016 (void);			/* RRB RFC	6016	*/
extern void	i6020 (void);			/* PCE		6020	*/
extern void	i6021 (void);			/* PSF		6021	*/
extern unsigned s6021 (void);			/* PSF (skip test)	*/
extern void	i6022 (void);			/* PCF		6022	*/
extern void	i6024 (void);			/* PPC		6024	*/
extern void	i6026 (void);			/* PLS		6026	*/
