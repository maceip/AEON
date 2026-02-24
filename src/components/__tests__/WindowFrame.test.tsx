import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { WindowFrame } from '../WindowFrame';
import React from 'react';
import '@testing-library/jest-dom';

// Mock dnd-kit
vi.mock('@dnd-kit/sortable', () => ({
  useSortable: () => ({
    attributes: {},
    listeners: {},
    setNodeRef: () => {},
    transform: null,
    transition: null,
    isDragging: false,
  }),
  SortableContext: ({ children }: any) => <div>{children}</div>,
  rectSortingStrategy: {},
}));

describe('WindowFrame', () => {
  const props = {
    id: 'test-frame',
    title: 'Test Window',
    onClose: vi.fn(),
    onMinimize: vi.fn(),
    onMaximize: vi.fn(),
    onRestore: vi.fn(),
    onShare: vi.fn(),
    onPopout: vi.fn(),
    onTogglePause: vi.fn(),
    isMaximized: false,
    isMinimized: false,
  };

  it('renders title and controls', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    expect(screen.getByText('Test Window')).toBeTruthy();
    expect(screen.getByText('Content')).toBeTruthy();
  });

  it('calls minimize when button clicked and has aria-label', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    // We try to find by accessible name "Minimize".
    // If aria-label is missing but title="Minimize" is present, this MIGHT pass in some envs
    // but explicit assertion on aria-label ensures we did the right thing.
    const minBtn = screen.getByRole('button', { name: 'Minimize' });
    expect(minBtn).toHaveAttribute('aria-label', 'Minimize');
    fireEvent.click(minBtn);
    expect(props.onMinimize).toHaveBeenCalled();
  });

  it('calls maximize when button clicked and has aria-label', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    const maxBtn = screen.getByRole('button', { name: 'Maximize' });
    expect(maxBtn).toHaveAttribute('aria-label', 'Maximize');
    fireEvent.click(maxBtn);
    expect(props.onMaximize).toHaveBeenCalled();
  });

  it('calls close when button clicked and has aria-label', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    const closeBtn = screen.getByRole('button', { name: 'Close' });
    expect(closeBtn).toHaveAttribute('aria-label', 'Close');
    fireEvent.click(closeBtn);
    expect(props.onClose).toHaveBeenCalled();
  });

  it('calls popout when button clicked and has aria-label', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    const popoutBtn = screen.getByRole('button', { name: 'Pop Out' });
    expect(popoutBtn).toHaveAttribute('aria-label', 'Pop Out');
    fireEvent.click(popoutBtn);
    expect(props.onPopout).toHaveBeenCalled();
  });

  it('hides content when minimized', () => {
    render(<WindowFrame {...props} isMinimized={true}><div>HiddenContent</div></WindowFrame>);
    // Content is wrapped in a div with 'hidden' class
    const content = screen.getByText('HiddenContent');
    expect(content.parentElement).toHaveClass('hidden');
  });
});
