"use client";
import React, { useEffect, useRef, useState, useCallback } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { useSidebar } from "../context/SidebarContext";
import {
  BoxCubeIcon,
  ChevronDownIcon,
  GridIcon,
  HorizontaLDots,
  ListIcon,
  PageIcon,
  PieChartIcon,
  TableIcon,
  UserCircleIcon,
} from "../icons/index";
import { menuService, MenuItem } from "@/lib/services";

type NavItem = {
  name: string;
  icon: React.ReactNode;
  path?: string;
  subItems?: { name: string; path: string }[];
};

export default function AppSidebar() {
  const { isExpanded, isMobileOpen, isHovered, setIsHovered } = useSidebar();
  const pathname = usePathname();

  const [dynamicNavItems, setDynamicNavItems] = useState<NavItem[]>([]);
  const [openSubmenu, setOpenSubmenu] = useState<{
    type: "main" | "others";
    index: number;
  } | null>(null);
  const [subMenuHeight, setSubMenuHeight] = useState<{ [key: string]: number }>({});
  const subMenuRefs = useRef<{ [key: string]: HTMLDivElement | null }>({});

  useEffect(() => {
    const fetchMenus = async () => {
      try {
        const userStr = localStorage.getItem("user");
        if (userStr) {
          const user = JSON.parse(userStr);
          const res = await menuService.getMenuTree(user.roleId, user.companyId);
          if (res.success && res.data) {
            const mappedItems: NavItem[] = res.data.map((item: MenuItem) => {
              const getIcon = (iconName?: string) => {
                if (!iconName) return <GridIcon />;
                switch (iconName.toLowerCase()) {
                  case 'piechart': return <PieChartIcon />;
                  case 'usercircle': return <UserCircleIcon />;
                  case 'boxcube': return <BoxCubeIcon />;
                  case 'list': return <ListIcon />;
                  case 'page': return <PageIcon />;
                  case 'table': return <TableIcon />;
                  case 'settings': return <GridIcon />; // fallback
                  default: return <GridIcon />;
                }
              };

              // Filter out items where the user does not have CanView permission
              if (user.tenant !== 1 && (!item.permissions || !item.permissions.canView)) return null;

              const navItem: NavItem = {
                name: item.menuName,
                icon: getIcon(item.icon),
                path: item.children && item.children.length > 0 ? undefined : (item.url || "/"),
                subItems: item.children && item.children.length > 0 ? item.children.filter(c => user.tenant === 1 || c.permissions?.canView).map(c => ({
                  name: c.menuName,
                  path: c.url || "/",
                })) : undefined,
              };
              
              return navItem;
            }).filter((item): item is NavItem => item !== null);
            
            setDynamicNavItems(mappedItems);
          }
        }
      } catch (err) {
        console.error("Failed to load dynamic menus", err);
      }
    };

    fetchMenus();
  }, []);

  const isActive = useCallback((path: string) => path === pathname, [pathname]);

  const toggleSubmenu = (type: "main" | "others", index: number) => {
    setOpenSubmenu((prevOpenSubmenu) => {
      if (prevOpenSubmenu && prevOpenSubmenu.type === type && prevOpenSubmenu.index === index) {
        return null;
      }
      return { type, index };
    });
  };

  useEffect(() => {
    if (openSubmenu !== null) {
      const key = `${openSubmenu.type}-${openSubmenu.index}`;
      if (subMenuRefs.current[key]) {
        setSubMenuHeight((prevHeights) => ({
          ...prevHeights,
          [key]: subMenuRefs.current[key]?.scrollHeight || 0,
        }));
      }
    }
  }, [openSubmenu]);

  const navList = dynamicNavItems;

  return (
    <aside
      className={`fixed top-0 left-0 z-50 flex flex-col h-screen px-5 bg-white border-r border-gray-200 dark:bg-gray-900 dark:border-gray-800 transition-all duration-300 ease-in-out ${
        isExpanded || isHovered || isMobileOpen ? "w-[290px]" : "w-[90px]"
      } ${isMobileOpen ? "translate-x-0" : "-translate-x-full lg:translate-x-0"}`}
      onMouseEnter={() => !isExpanded && setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <div className="py-6 flex items-center justify-between">
        <Link href="/">
          {isExpanded || isHovered || isMobileOpen ? (
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 rounded-xl overflow-hidden flex items-center justify-center shadow-md bg-white">
                <Image
                  src="/images/logo/logo-icon.png"
                  alt="Callalyze Logo"
                  width={40}
                  height={40}
                  className="object-cover"
                />
              </div>
              <span className="text-xl font-extrabold bg-clip-text text-transparent bg-gradient-to-r from-gray-900 via-brand-600 to-indigo-600 dark:from-white dark:to-indigo-400">
                Callalyze
              </span>
            </div>
          ) : (
            <div className="w-10 h-10 rounded-xl overflow-hidden flex items-center justify-center shadow-md bg-white">
              <Image
                src="/images/logo/logo-icon.png"
                alt="Callalyze Logo"
                width={40}
                height={40}
                className="object-cover"
              />
            </div>
          )}
        </Link>
      </div>

      <div className="flex flex-col overflow-y-auto duration-300 ease-linear no-scrollbar">
        <nav className="mb-6">
          <div className="flex flex-col gap-4">
            <div>
              <h2 className={`mb-4 text-xs uppercase leading-[20px] font-semibold text-gray-400 ${!isExpanded && !isHovered && !isMobileOpen ? "lg:justify-center flex" : ""}`}>
                {isExpanded || isHovered || isMobileOpen ? "Main Menu" : <HorizontaLDots />}
              </h2>

              <ul className="flex flex-col gap-2">
                {navList.map((nav, index) => {
                  const hasSubItems = nav.subItems && nav.subItems.length > 0;
                  return (
                    <li key={nav.name}>
                      {hasSubItems ? (
                        <button
                          onClick={() => toggleSubmenu("main", index)}
                          className={`menu-item group flex items-center justify-between w-full p-3 rounded-lg text-sm font-medium transition-colors ${
                            openSubmenu?.type === "main" && openSubmenu?.index === index
                              ? "bg-brand-50 text-brand-600 dark:bg-brand-950/50 dark:text-brand-400"
                              : "text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
                          }`}
                        >
                          <div className="flex items-center gap-3 overflow-hidden">
                            <span className="w-5 h-5 flex-shrink-0 flex items-center justify-center">{nav.icon}</span>
                            {(isExpanded || isHovered || isMobileOpen) && (
                              <span className="text-left leading-tight break-words">{nav.name}</span>
                            )}
                          </div>
                          {(isExpanded || isHovered || isMobileOpen) && (
                            <ChevronDownIcon
                              className={`w-4 h-4 flex-shrink-0 ml-2 transition-transform duration-200 ${
                                openSubmenu?.type === "main" && openSubmenu?.index === index ? "rotate-180" : ""
                              }`}
                            />
                          )}
                        </button>
                      ) : (
                        nav.path && (
                          <Link
                            href={nav.path}
                            className={`menu-item group flex items-center gap-3 p-3 rounded-lg text-sm font-medium transition-colors ${
                              isActive(nav.path)
                                ? "bg-brand-500 text-white shadow-md shadow-brand-500/20"
                                : "text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
                            }`}
                          >
                            <span className="w-5 h-5 flex-shrink-0 flex items-center justify-center">{nav.icon}</span>
                            {(isExpanded || isHovered || isMobileOpen) && (
                              <span className="text-left leading-tight break-words">{nav.name}</span>
                            )}
                          </Link>
                        )
                      )}

                    {nav.subItems && (isExpanded || isHovered || isMobileOpen) && (
                      <div
                        ref={(el) => { subMenuRefs.current[`main-${index}`] = el; }}
                        className="overflow-hidden transition-all duration-300 ease-in-out"
                        style={{
                          height: openSubmenu?.type === "main" && openSubmenu?.index === index
                            ? `${subMenuHeight[`main-${index}`]}px`
                            : "0px",
                        }}
                      >
                        <ul className="pl-6 pt-1.5 pb-1 flex flex-col gap-1 border-l-2 border-brand-100 dark:border-gray-800 ml-4 my-1">
                          {nav.subItems.map((subItem) => (
                            <li key={subItem.name}>
                              <Link
                                href={subItem.path}
                                className={`text-sm block py-2 px-3 rounded-lg transition-all ${
                                  isActive(subItem.path)
                                    ? "text-brand-600 font-semibold bg-brand-50/80 dark:bg-brand-950/60 dark:text-brand-400 border border-brand-100 dark:border-brand-900/40"
                                    : "text-gray-600 hover:text-gray-900 hover:bg-gray-50 dark:text-gray-400 dark:hover:text-white dark:hover:bg-gray-800/60"
                                }`}
                              >
                                {subItem.name}
                              </Link>
                            </li>
                          ))}
                        </ul>
                      </div>
                    )}
                  </li>
                );
              })}
              </ul>
            </div>
          </div>
        </nav>
      </div>
    </aside>
  );
}
