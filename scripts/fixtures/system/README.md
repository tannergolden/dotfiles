# scripts/fixtures/system/

The machine the monitor is looking at when `SYSTEM_MOCK=1`. A 16-inch M3 Max
called `moonbase`: 36 GB, six days up, two thirds of its disk gone, a little
swap, one link down, and a cell charging rather than sitting at 100. The
numbers were chosen to exercise the card rather than to flatter it.

**It is a folder rather than four hundred lines of Python** because a fixture
is data. It was pulled out of the monitor's Python original for a second
reader — `scripts/suite/system.zsh`, which reads these files byte for byte —
and it stays out because the move was worth making on its own: a canned
`vm_stat` reads as a canned `vm_stat` here and read as a Python string
literal there, and the extraction is what surfaced the clock below.

```
sysctl.tab        key<TAB>value · the ten sysctls the card asks for
vm_stat.txt       the page counters, verbatim
df.txt            -k, every volume
netstat-ib.txt    interfaces: packets, bytes, errors
netstat-tcp.txt   sockets, for the established/listening/waiting counts
ioreg-disk.txt    IOBlockStorageDriver · bytes and operations, read and written
ioreg-batt.txt    AppleSmartBattery · capacity, cycles, volts, amps
ioreg-hid.txt     bluetooth devices and their charge
pmset-batt.txt    the charge, the state and the estimate
ps.txt            108 processes · the twenty-two worth looking at, and
                  the long tail of daemons behind them
seed.tab          the readings the fixture starts holding
```

**Unknown commands fall through.** Anything not answered here runs for real,
which is what keeps the way-out path — it walks its own parent with `ps` —
honest even in demo mode.

**The long tail is written out, not generated.** Eighty-six of those `ps`
rows used to be dealt from a name table by a few lines of Python — the same
list every run, which is all a fixture needs. It is rows now: a generator is
code, and code in a fixture is a thing that has to be *reimplemented* by
anything else that reads it rather than simply read.

**`seed.tab` is the state, not a command.** A trace is a record of the last
half hour and a per-core percentage is the difference between two readings, so
a card that had only just started would draw an empty history and sixteen
cores at zero — a true picture of a machine that was switched on a second ago
and a useless one of a machine at work. The fixture therefore arrives having
already been running: the histories are written down, and so is the tick table
the first delta is taken against.

**Editing any of this changes `probe.expected`.** It is every reading the
monitor takes from this fixture, flat and sorted — what the Python original
printed, and what `SYSTEM_MOCK=1 zsh scripts/suite/system.zsh --probe` still
prints byte for byte. Regenerate it with that command when you change a
number here.
